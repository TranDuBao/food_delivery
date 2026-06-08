// models/groupOrderModel.js
const db = require('../config/db');

const GroupOrderModel = {

  // ── Giỏ hàng nhóm ────────────────────────────────────────────────────────

  /** Lấy toàn bộ giỏ hàng nhóm (kèm thông tin món ăn và người thêm) */
  getGroupCart: async (maNhom) => {
    const rows = await db.query(`
      SELECT
        gn.maGioHangNhom,
        gn.maNhom,
        gn.maTaiKhoan,
        gn.maMonAn,
        gn.soLuong,
        gn.ghiChu,
        gn.thoiGianThem,
        m.tenMonAn,
        m.giaTien,
        m.hinhAnh,
        m.maGianHang,
        gh.tenGianHang,
        t.hoTen AS tenNguoiThem,
        t.anhDaiDien AS anhNguoiThem
      FROM giohang_nhom gn
      JOIN monan m ON gn.maMonAn = m.maMonAn
      JOIN gianhang gh ON m.maGianHang = gh.maGianHang
      JOIN taikhoan t ON gn.maTaiKhoan = t.maTaiKhoan
      WHERE gn.maNhom = ?
      ORDER BY gn.thoiGianThem DESC
    `, [maNhom]);
    // Chuyển decimal → number để Flutter không bị lỗi kiểu dữ liệu
    return rows.map(r => ({
      ...r,
      giaTien: Number(r.giaTien),
      soLuong: Number(r.soLuong),
      maGioHangNhom: Number(r.maGioHangNhom),
      maTaiKhoan: Number(r.maTaiKhoan),
      maMonAn: Number(r.maMonAn),
      maGianHang: Number(r.maGianHang),
    }));
  },

  /** Thêm/cập nhật món vào giỏ hàng nhóm */
  addToGroupCart: async (maNhom, maTaiKhoan, maMonAn, soLuong, ghiChu = null) => {
    // Kiểm tra đã có chưa (cùng người + cùng món)
    const existing = await db.query(
      `SELECT maGioHangNhom, soLuong FROM giohang_nhom WHERE maNhom = ? AND maTaiKhoan = ? AND maMonAn = ?`,
      [maNhom, maTaiKhoan, maMonAn]
    );

    if (existing.length > 0) {
      const newQty = existing[0].soLuong + soLuong;
      await db.query(
        `UPDATE giohang_nhom SET soLuong = ?, ghiChu = ?, thoiGianThem = NOW() WHERE maGioHangNhom = ?`,
        [newQty, ghiChu, existing[0].maGioHangNhom]
      );
      return { action: 'updated', maGioHangNhom: existing[0].maGioHangNhom, soLuong: newQty };
    }

    const result = await db.query(
      `INSERT INTO giohang_nhom (maNhom, maTaiKhoan, maMonAn, soLuong, ghiChu, thoiGianThem) VALUES (?, ?, ?, ?, ?, NOW())`,
      [maNhom, maTaiKhoan, maMonAn, soLuong, ghiChu]
    );
    return { action: 'added', maGioHangNhom: result.insertId, soLuong };
  },

  /** Cập nhật số lượng của 1 dòng giỏ nhóm */
  updateGroupCartItem: async (maGioHangNhom, maTaiKhoan, soLuong) => {
    if (soLuong <= 0) {
      // Nếu số lượng <= 0 thì xoá
      await db.query(
        `DELETE FROM giohang_nhom WHERE maGioHangNhom = ? AND maTaiKhoan = ?`,
        [maGioHangNhom, maTaiKhoan]
      );
      return { deleted: true };
    }
    await db.query(
      `UPDATE giohang_nhom SET soLuong = ? WHERE maGioHangNhom = ? AND maTaiKhoan = ?`,
      [soLuong, maGioHangNhom, maTaiKhoan]
    );
    return { deleted: false, soLuong };
  },

  /** Xoá 1 dòng giỏ nhóm */
  removeGroupCartItem: async (maGioHangNhom, maTaiKhoan) => {
    await db.query(
      `DELETE FROM giohang_nhom WHERE maGioHangNhom = ? AND maTaiKhoan = ?`,
      [maGioHangNhom, maTaiKhoan]
    );
    return { success: true };
  },

  /** Xoá toàn bộ giỏ nhóm (sau khi checkout) */
  clearGroupCart: async (maNhom, connection = null) => {
    const query = connection
      ? (sql, params) => connection.execute(sql, params)
      : (sql, params) => db.query(sql, params);
    await query(`DELETE FROM giohang_nhom WHERE maNhom = ?`, [maNhom]);
  },

  // ── Kiểm tra thành viên ────────────────────────────────────────────────────

  isMember: async (maNhom, maTaiKhoan) => {
    const rows = await db.query(
      `SELECT maThanhVienNhom FROM thanhvien_nhom WHERE maNhom = ? AND maTaiKhoan = ?`,
      [maNhom, maTaiKhoan]
    );
    return rows.length > 0;
  },

  // ── Group checkout ─────────────────────────────────────────────────────────

  /**
   * Tạo đơn hàng cho từng thành viên trong giỏ nhóm.
   * Mỗi người sẽ có 1 đơn hàng riêng, liên kết qua maNhom (lưu vào ghi chú).
   * maToaNha, maPhong lấy từng user (nếu user chưa set → dùng default).
   * Trả về danh sách maDonHang đã tạo.
   */
  groupCheckout: async ({ maNhom, maToaNha, maPhong, phuongThucThanhToan = 'COD' }) => {
    return db.withTransaction(async (connection) => {
      // Lấy giỏ hàng nhóm
      const [cartRows] = await connection.execute(`
        SELECT
          gn.maTaiKhoan,
          gn.maMonAn,
          gn.soLuong,
          gn.ghiChu,
          m.giaTien,
          m.tenMonAn,
          m.soLuongTon,
          m.daXoa,
          m.trangThai
        FROM giohang_nhom gn
        JOIN monan m ON gn.maMonAn = m.maMonAn
        WHERE gn.maNhom = ?
      `, [maNhom]);

      if (!cartRows || cartRows.length === 0) {
        throw new Error('Giỏ hàng nhóm đang trống');
      }

      // Kiểm tra tồn kho và trạng thái món
      for (const item of cartRows) {
        if (item.daXoa === 1) throw new Error(`"${item.tenMonAn}" đã ngừng bán`);
        if ((item.soLuongTon ?? 99) < item.soLuong) {
          throw new Error(`"${item.tenMonAn}" chỉ còn ${item.soLuongTon} phần`);
        }
      }

      // Nhóm theo maTaiKhoan
      const byUser = {};
      for (const item of cartRows) {
        const uid = item.maTaiKhoan;
        if (!byUser[uid]) byUser[uid] = [];
        byUser[uid].push(item);
      }

      const createdOrderIds = [];

      for (const [uid, items] of Object.entries(byUser)) {
        const tongTien = items.reduce((sum, i) => sum + Number(i.giaTien) * Number(i.soLuong), 0);

        // Tạo đơn hàng
        const [orderRes] = await connection.execute(
          `INSERT INTO donhang
            (maTaiKhoan, maToaNha, maPhong, tongTien, trangThaiDonHang, phuongThucThanhToan, thoiGianDat)
           VALUES (?, ?, ?, ?, 'choGhepDon', ?, NOW())`,
          [uid, maToaNha, maPhong, tongTien, phuongThucThanhToan]
        );
        const newOrderId = orderRes.insertId;
        createdOrderIds.push({ maDonHang: newOrderId, maTaiKhoan: parseInt(uid) });

        // Tạo chi tiết
        for (const item of items) {
          for (let i = 0; i < item.soLuong; i++) {
            await connection.execute(
              `INSERT INTO chitietdonhang (maDonHang, maMonAn, soLuong, giaTien, trangThaiMon, ghiChu)
               VALUES (?, ?, 1, ?, 'pending', ?)`,
              [newOrderId, item.maMonAn, item.giaTien, item.ghiChu]
            );
          }

          // Trừ tồn kho
          const [upd] = await connection.execute(
            `UPDATE monan SET soLuongTon = soLuongTon - ? WHERE maMonAn = ? AND soLuongTon >= ?`,
            [item.soLuong, item.maMonAn, item.soLuong]
          );
          if (upd.affectedRows === 0) {
            throw new Error(`Lỗi tồn kho khi trừ "${item.tenMonAn}"`);
          }
        }
      }

      // Xoá giỏ nhóm
      await connection.execute(`DELETE FROM giohang_nhom WHERE maNhom = ?`, [maNhom]);

      return createdOrderIds;
    });
  },

  // ── Tính discount theo số thành viên đặt ──────────────────────────────────
  calcDiscount: (memberCount) => {
    if (memberCount >= 10) return 0.10;
    if (memberCount >= 7) return 0.08;
    if (memberCount >= 5) return 0.05;
    if (memberCount >= 3) return 0.03;
    return 0;
  },
};

module.exports = GroupOrderModel;
