// models/canteenModel.js
const db = require('../config/db');

const GianHangModel = {
    // [DÀNH CHO KHÁCH HÀNG] Lấy danh sách tất cả gian hàng (chỉ active)
    getAll: async () => {
        const rows = await db.query('SELECT * FROM gianHang WHERE trangThai = 1');
        return rows;
    },

    // [DÀNH CHO KHÁCH HÀNG] Lấy thông tin chi tiết của 1 gian hàng
    findById: async (maGianHang) => {
        const rows = await db.query(
            'SELECT * FROM gianHang WHERE maGianHang = ?',
            [maGianHang]
        );
        return rows[0];
    },

    // [DÀNH CHO KHÁCH HÀNG] Lấy rating trung bình của gian hàng (từ bảng danhgia + monan)
    getStoreRating: async (maGianHang) => {
        const rows = await db.query(
            `SELECT 
                ROUND(AVG(dg.soSao), 1) AS avgRating,
                COUNT(dg.maDanhGia) AS totalReviews
             FROM danhgia dg
             JOIN monan m ON dg.maMonAn = m.maMonAn
             WHERE m.maGianHang = ?`,
            [maGianHang]
        );
        return rows[0] || { avgRating: null, totalReviews: 0 };
    },

    // [DÀNH CHO KHÁCH HÀNG] Lấy top 3 món nổi bật của gian hàng
    getTopDishes: async (maGianHang, limit = 3) => {
        const rows = await db.query(
            `SELECT 
                m.maMonAn, m.tenMonAn, m.hinhAnh, m.giaTien,
                COALESCE(m.diemDanhGia, 0) AS diemDanhGia,
                COALESCE(m.luotDanhGia, 0) AS luotDanhGia,
                COALESCE(m.soLuongDaBan, 0) AS soLuongDaBan
             FROM monAn m
             WHERE m.maGianHang = ? AND m.daXoa = 0 AND m.trangThai = 1
             ORDER BY 
                (COALESCE(m.diemDanhGia, 0) * 0.5 + COALESCE(m.soLuongDaBan, 0) * 0.5) DESC,
                m.maMonAn ASC
             LIMIT ?`,
            [maGianHang, limit]
        );
        return rows;
    },

    // [DÀNH CHO CHỦ QUÁN] Lấy thông tin gian hàng dựa vào maTaiKhoan
    findByOwnerId: async (maTaiKhoan) => {
        const rows = await db.query(
            'SELECT * FROM gianHang WHERE maTaiKhoan = ?',
            [maTaiKhoan]
        );
        return rows[0];
    },

    // [DÀNH CHO CHỦ QUÁN] Tạo gian hàng mới
    create: async (maTaiKhoan, tenGianHang) => {
        const result = await db.query(
            'INSERT INTO gianHang (maTaiKhoan, tenGianHang) VALUES (?, ?)',
            [maTaiKhoan, tenGianHang]
        );
        return result.insertId;
    },

    // [DÀNH CHO CHỦ QUÁN] Cập nhật thông tin gian hàng
    update: async (maGianHang, data) => {
        const { tenGianHang, moTa, banner, soDienThoai, gioMoCua } = data;
        const result = await db.query(
            `UPDATE gianHang 
             SET tenGianHang = ?, moTa = ?, banner = ?, soDienThoai = ?, gioMoCua = ?
             WHERE maGianHang = ?`,
            [tenGianHang, moTa, banner, soDienThoai, gioMoCua, maGianHang]
        );
        return result.affectedRows > 0;
    },

    /* ==============================================================
       QUẢN LÝ ĐƠN HÀNG DÀNH CHO ROLE 2 (CẬP NHẬT TRẠNG THÁI MÓN ĂN)
       Lưu ý: Mặc định DB cũ không có trangThai trong chiTietDonHang, 
       chúng ta phải dùng IFNULL kiểm tra trạng thái món.
       ============================================================== */

    getPendingOrdersForStore: async (maGianHang) => {
        const rows = await db.query(
            `SELECT 
                ct.maChiTietDonHang, 
                ct.maDonHang, 
                ct.soLuong, 
                m.tenMonAn, 
                tn.tenToaNha, p.tenPhong,
                IFNULL(ct.trangThaiMon, 'dangChuanBi') as trangThaiMon, 
                d.maNhomGiaoHang
             FROM chitietdonhang ct
             JOIN monan m ON ct.maMonAn = m.maMonAn
             JOIN donhang d ON ct.maDonHang = d.maDonHang
             LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
             LEFT JOIN phong p ON d.maPhong = p.maPhong
             WHERE m.maGianHang = ? 
               AND d.trangThaiDonHang = 'dangChuanBi'
               AND (ct.trangThaiMon IS NULL OR ct.trangThaiMon = 'dangChuanBi')`,
            [maGianHang]
        );
        return rows;
    },

    // [DÀNH CHO CHỦ QUÁN] Cập nhật trạng thái một món trong chiTietDonHang sang `daXong`
    updateDishStatus: async (maChiTietDonHang, maGianHang) => {
        // Kiểm tra xem món này có thuộc gian hàng này không (tránh lỗi bảo mật)
        const checkRows = await db.query(
            `SELECT ct.maDonHang, d.maNhomGiaoHang 
              FROM chitietdonhang ct
              JOIN monan m ON ct.maMonAn = m.maMonAn
              JOIN donhang d ON ct.maDonHang = d.maDonHang
              WHERE ct.maChiTietDonHang = ? AND m.maGianHang = ?`,
            [maChiTietDonHang, maGianHang]
        );

        if (checkRows.length === 0) return null; // Không hợp lệ

        const { maDonHang, maNhomGiaoHang } = checkRows[0];

        // Do SQL mặc định chưa có cột trangThaiMon, nên nếu lỗi có nghĩa là chưa có cột. 
        // Trong dự án thực tế ta sẽ ALTER TABLE để thêm cột này. Nhưng ta giả định cột này có sẵn.
        try {
            await db.query(`UPDATE chitietdonhang SET trangThaiMon = 'daXong' WHERE maChiTietDonHang = ?`, [maChiTietDonHang]);
        } catch (e) {
            if (e.code === 'ER_BAD_FIELD_ERROR') {
                // Tự động thêm cột vào nếu rớt cấu trúc :)
                await db.query(`ALTER TABLE chitietdonhang ADD COLUMN trangThaiMon VARCHAR(50) DEFAULT 'dangChuanBi'`);
                await db.query(`UPDATE chitietdonhang SET trangThaiMon = 'daXong' WHERE maChiTietDonHang = ?`, [maChiTietDonHang]);
            } else throw e;
        }

        return { maDonHang, maNhomGiaoHang };
    },

    // Kiểm tra và chuyển trạng thái nhóm nếu tất cả các món trong TẤT CẢ các đơn của nhóm đều báo xong
    checkAndUpdateGroupStatusIfDone: async (maNhomGiaoHang) => {
        // Lấy tổng số món ăn trong nhóm này
        const totalRows = await db.query(
            `SELECT COUNT(*) as d 
             FROM chitietdonhang ct
             JOIN donhang d ON ct.maDonHang = d.maDonHang
             WHERE d.maNhomGiaoHang = ?`,
            [maNhomGiaoHang]
        );
        const totalItemsInGroup = totalRows[0].d;

        // Lấy số món đã hoàn thành ('daXong')
        const doneRows = await db.query(
            `SELECT COUNT(*) as c 
              FROM chitietdonhang ct
              JOIN donhang d ON ct.maDonHang = d.maDonHang
              WHERE d.maNhomGiaoHang = ? AND ct.trangThaiMon = 'daXong'`,
            [maNhomGiaoHang]
        );
        const doneItemsInGroup = doneRows[0].c;

        if (totalItemsInGroup === doneItemsInGroup && totalItemsInGroup > 0) {
            // Tất cả xong! Đẩy đơn cho shipper.
            await db.query(`UPDATE donhang SET trangThaiDonHang = 'choGiaoHang' WHERE maNhomGiaoHang = ?`, [maNhomGiaoHang]);
            // Nhóm giao hàng thật ra đã có trangThaiNhom là 'choGiaoHang' lúc gom, nên không cần sửa lại trangThaiNhom, chỉ cần trigger donhang
            return true;
        }
        return false;
    }
};

module.exports = GianHangModel;