// controllers/adminController.js
const { query } = require('../config/db');
const bcrypt = require('bcrypt');
const { saveCroppedDishImage } = require('../config/upload');

// Tự động thêm cột trangThai vào bảng taikhoan và gianhang nếu chưa có
async function ensureAdminColumns() {
  await query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS trangThai TINYINT(1) NOT NULL DEFAULT 1`).catch(() => { });
  await query(`ALTER TABLE gianhang ADD COLUMN IF NOT EXISTS trangThai TINYINT(1) NOT NULL DEFAULT 1`).catch(() => { });
  await query(`ALTER TABLE chitietdonhang ADD COLUMN IF NOT EXISTS maNhomGiaoHang INT NULL`).catch(() => { });
  // Cho phép maGianHang = NULL để voucher admin áp dụng toàn sàn
  await query(`ALTER TABLE giamgia MODIFY COLUMN maGianHang INT NULL`).catch(() => { });
  // Thêm cột nguonVoucher để phân biệt voucher admin vs quán
  await query("ALTER TABLE giamgia ADD COLUMN IF NOT EXISTS nguonVoucher ENUM('admin','store') NOT NULL DEFAULT 'store'").catch(() => { });
  // Thêm cột ghiChu vào chitietdonhang
  await query(`ALTER TABLE chitietdonhang ADD COLUMN IF NOT EXISTS ghiChu VARCHAR(255) NULL`).catch(() => { });
  // Thêm cột khóa tài khoản có thời hạn
  await query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS thoiGianKhoa DATETIME NULL`).catch((e) => { console.log('thoiGianKhoa:', e.message); });
  await query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS khoaVinhVien TINYINT(1) NOT NULL DEFAULT 0`).catch((e) => { console.log('khoaVinhVien:', e.message); });
}
// Gọi ngay khi module được load
ensureAdminColumns();

const AdminController = {

  // ══════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════
  getDashboard: async (req, res, next) => {
    try {
      const statsRows = await query(`
        SELECT
          (SELECT COUNT(*) FROM taikhoan)                             AS tongTaiKhoan,
          (SELECT COUNT(*) FROM taikhoan WHERE maVaiTro = 1)          AS tongKhachHang,
          (SELECT COUNT(*) FROM taikhoan WHERE maVaiTro = 2)          AS tongNhanVien,
          (SELECT COUNT(*) FROM gianhang)                             AS tongGianHang,
          (SELECT COUNT(*) FROM donhang)                              AS tongDonHang,
          (SELECT COALESCE(SUM(tongTien),0) FROM donhang
            WHERE trangThaiDonHang IN ('daGiao','choGiaoHang'))       AS tongDoanhThu,
          (SELECT COUNT(*) FROM giamgia WHERE trangThai = TRUE)       AS tongVoucher
      `);

      const recentOrders = await query(`
        SELECT d.maDonHang, tk.hoTen AS tenKhach,
               d.tongTien, d.trangThaiDonHang, d.thoiGianDat,
               tn.tenToaNha
        FROM donhang d
        JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
        LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
        ORDER BY d.thoiGianDat DESC LIMIT 10
      `);

      // statsRows là array, lấy phần tử đầu tiên
      const stats = Array.isArray(statsRows) ? (statsRows[0] || {}) : statsRows;

      res.json({ success: true, data: { stats, recentOrders } });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ GIAN HÀNG (CĂN TIN)
  // ══════════════════════════════════════════════════════════════════

  /** GET /api/admin/stores */
  getStores: async (req, res, next) => {
    try {
      const rows = await query(`
        SELECT g.maGianHang, g.tenGianHang, g.moTa, g.banner AS hinhAnh,
               g.trangThai,
               tk.hoTen AS tenChuQuan, tk.email, tk.maTaiKhoan,
               COUNT(DISTINCT d.maDonHang) AS tongDon,
               COALESCE(SUM(CASE WHEN d.trangThaiDonHang IN ('daGiao','choGiaoHang') THEN d.tongTien ELSE 0 END),0) AS doanhThu
        FROM gianhang g
        LEFT JOIN taikhoan tk ON g.maTaiKhoan = tk.maTaiKhoan
        LEFT JOIN monan m2 ON m2.maGianHang = g.maGianHang
        LEFT JOIN chitietdonhang ct ON ct.maMonAn = m2.maMonAn
        LEFT JOIN donhang d ON d.maDonHang = ct.maDonHang
        GROUP BY g.maGianHang
        ORDER BY g.maGianHang DESC
      `);
      // Build full URL cho banner
      const buildUrl = (p) => (!p ? '' : p.startsWith('http') ? p : `${req.protocol}://${req.get('host')}${p}`);
      const data = rows.map(r => ({ ...r, hinhAnh: buildUrl(r.hinhAnh) }));
      res.json({ success: true, data });
    } catch (err) { next(err); }
  },

  /** POST /api/admin/stores — Tạo gian hàng mới + tài khoản staff */
  createStore: async (req, res, next) => {
    try {
      const { tenGianHang, moTa, tenDangNhap, matKhau, hoTen, email, soDienThoai } = req.body;
      if (!tenGianHang || !tenDangNhap || !matKhau)
        return res.status(400).json({ success: false, message: 'Thiếu thông tin bắt buộc.' });

      // Tạo tài khoản nhân viên (role 2)
      const hash = await bcrypt.hash(matKhau, 10);
      const accResult = await query(
        `INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, soDienThoai, maVaiTro, trangThai)
         VALUES (?, ?, ?, ?, ?, 2, 1)`,
        [tenDangNhap, hash, hoTen || tenDangNhap, email || null, soDienThoai || null]
      );
      const maTaiKhoan = accResult.insertId;

      // Tạo gian hàng liên kết với tài khoản đó
      const storeResult = await query(
        `INSERT INTO gianhang (tenGianHang, moTa, maTaiKhoan, trangThai) VALUES (?, ?, ?, 1)`,
        [tenGianHang, moTa || '', maTaiKhoan]
      );

      res.status(201).json({ success: true, message: 'Tạo gian hàng thành công!', data: { maGianHang: storeResult.insertId, maTaiKhoan } });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ success: false, message: 'Tên đăng nhập đã tồn tại.' });
      next(err);
    }
  },

  /** PUT /api/admin/stores/:id — Cập nhật thông tin / Khóa-mở gian hàng */
  updateStore: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { tenGianHang, moTa, trangThai } = req.body;
      await query(
        `UPDATE gianhang SET tenGianHang = COALESCE(?, tenGianHang),
                              moTa        = COALESCE(?, moTa),
                              trangThai   = COALESCE(?, trangThai)
         WHERE maGianHang = ?`,
        [tenGianHang ?? null, moTa ?? null, trangThai ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật gian hàng thành công!' });
    } catch (err) { next(err); }
  },

  /** DELETE /api/admin/stores/:id — Xóa mềm gian hàng (đặt trangThai = 0) */
  deleteStore: async (req, res, next) => {
    try {
      const { id } = req.params;
      await query(`UPDATE gianhang SET trangThai = 0 WHERE maGianHang = ?`, [id]);
      res.json({ success: true, message: 'Đã đóng cửa / xóa gian hàng thành công!' });
    } catch (err) { next(err); }
  },

  /** GET /api/admin/monthly-stats — Doanh thu 6 tháng gần nhất */
  getMonthlyStats: async (req, res, next) => {
    try {
      const rows = await query(`
        SELECT
          DATE_FORMAT(thoiGianDat, '%Y-%m') AS thang,
          COUNT(*)                           AS tongDon,
          COALESCE(SUM(CASE WHEN trangThaiDonHang IN ('daGiao','choGiaoHang') THEN tongTien ELSE 0 END), 0) AS doanhThu
        FROM donhang
        WHERE thoiGianDat >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
        GROUP BY thang
        ORDER BY thang ASC
      `);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** GET /api/admin/orders — Tất cả đơn hàng */
  getOrders: async (req, res, next) => {
    try {
      const { status, limit = 50 } = req.query;
      const where = status ? `WHERE d.trangThaiDonHang = ?` : '';
      const params = status ? [status, parseInt(limit)] : [parseInt(limit)];
      const rows = await query(`
        SELECT d.maDonHang, tk.hoTen AS tenKhach, tk.soDienThoai,
               d.tongTien, d.trangThaiDonHang, d.thoiGianDat,
               tn.tenToaNha, p.tenPhong,
               GROUP_CONCAT(m.tenMonAn ORDER BY m.tenMonAn SEPARATOR ', ') AS danhSachMon
        FROM donhang d
        JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
        LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
        LEFT JOIN phong p ON d.maPhong = p.maPhong
        LEFT JOIN chitietdonhang ct ON ct.maDonHang = d.maDonHang
        LEFT JOIN monan m ON m.maMonAn = ct.maMonAn
        ${where}
        GROUP BY d.maDonHang
        ORDER BY d.thoiGianDat DESC
        LIMIT ?
      `, params);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** GET /api/admin/revenue-by-store — Doanh thu từng gian hàng */
  getRevenueByStore: async (req, res, next) => {
    try {
      const { filter = 'all' } = req.query;
      let timeClause = "";
      if (filter === 'day') timeClause = "AND d.thoiGianDat >= CURDATE()";
      else if (filter === 'month') timeClause = "AND d.thoiGianDat >= DATE_FORMAT(CURDATE(), '%Y-%m-01')";
      else if (filter === 'year') timeClause = "AND d.thoiGianDat >= DATE_FORMAT(CURDATE(), '%Y-01-01')";

      const rows = await query(`
        SELECT g.maGianHang, g.tenGianHang, g.banner,
               COUNT(DISTINCT d.maDonHang) AS tongDon,
               COALESCE(SUM(CASE WHEN d.trangThaiDonHang IN ('daGiao','choGiaoHang') THEN d.tongTien ELSE 0 END),0) AS doanhThu
        FROM gianhang g
        LEFT JOIN monan m ON m.maGianHang = g.maGianHang
        LEFT JOIN chitietdonhang ct ON ct.maMonAn = m.maMonAn
        LEFT JOIN donhang d ON d.maDonHang = ct.maDonHang ${timeClause}
        GROUP BY g.maGianHang
        ORDER BY doanhThu DESC
      `);
      const buildUrl = (p) => (!p ? '' : p.startsWith('http') ? p : `${req.protocol}://${req.get('host')}${p}`);
      res.json({ success: true, data: rows.map(r => ({ ...r, banner: buildUrl(r.banner) })) });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ TÀI KHOẢN
  // ══════════════════════════════════════════════════════════════════

  /**
   * GET /api/admin/users?role=1|2
   * Chỉ trả về role 1 (khách hàng) và role 2 (nhân viên), không lấy admin
   */
  getUsers: async (req, res, next) => {
    try {
      const { role } = req.query;
      let rows;
      if (role) {
        rows = await query(
          `SELECT maTaiKhoan, tenDangNhap, hoTen, email, soDienThoai,
                  maVaiTro, trangThai, thoiGianKhoa, khoaVinhVien
           FROM taikhoan
           WHERE maVaiTro = ? AND maVaiTro != 3
           ORDER BY maTaiKhoan DESC`,
          [role]
        );
      } else {
        rows = await query(
          `SELECT maTaiKhoan, tenDangNhap, hoTen, email, soDienThoai,
                  maVaiTro, trangThai, thoiGianKhoa, khoaVinhVien
           FROM taikhoan
           WHERE maVaiTro != 3
           ORDER BY maTaiKhoan DESC`
        );
      }
      // Tự động mở khóa nếu hết hạn
      const now = new Date();
      const toUnlock = rows.filter(
        u => u.trangThai === 0 && !u.khoaVinhVien && u.thoiGianKhoa && new Date(u.thoiGianKhoa) <= now
      );
      for (const u of toUnlock) {
        await query(
          `UPDATE taikhoan SET trangThai=1, thoiGianKhoa=NULL WHERE maTaiKhoan=?`,
          [u.maTaiKhoan]
        ).catch(() => {});
        u.trangThai = 1;
        u.thoiGianKhoa = null;
      }
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** POST /api/admin/users — Tạo tài khoản mới */
  createUser: async (req, res, next) => {
    try {
      const { tenDangNhap, matKhau, hoTen, email, soDienThoai, maVaiTro } = req.body;
      if (!tenDangNhap || !matKhau)
        return res.status(400).json({ success: false, message: 'Thiếu tên đăng nhập hoặc mật khẩu.' });
      // Không cho tạo tài khoản role admin qua API này
      const role = [1, 2].includes(Number(maVaiTro)) ? Number(maVaiTro) : 1;
      const hash = await bcrypt.hash(matKhau, 10);
      const result = await query(
        `INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, soDienThoai, maVaiTro, trangThai)
         VALUES (?, ?, ?, ?, ?, ?, 1)`,
        [tenDangNhap, hash, hoTen || tenDangNhap, email || null, soDienThoai || null, role]
      );
      res.status(201).json({ success: true, message: 'Tạo tài khoản thành công!', data: { maTaiKhoan: result.insertId } });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ success: false, message: 'Tên đăng nhập đã tồn tại.' });
      next(err);
    }
  },

  /**
   * PUT /api/admin/users/:id
   * Cập nhật thông tin / Khóa-mở / Active lại tài khoản
   * trangThai = 0 (khóa/xóa mềm), trangThai = 1 (active)
   * Không cho phép đổi về role admin (maVaiTro = 3)
   */
  updateUser: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { hoTen, email, soDienThoai, maVaiTro, trangThai, action, soNgay } = req.body;

      // Xử lý action khóa/mở khóa
      if (action === 'ban_days') {
        const days = parseInt(soNgay, 10);
        if (isNaN(days) || days <= 0)
          return res.status(400).json({ success: false, message: 'soNgay phải là số nguyên dương.' });
        const expireDate = new Date();
        expireDate.setDate(expireDate.getDate() + days);
        await query(
          `UPDATE taikhoan SET trangThai=0, khoaVinhVien=0, thoiGianKhoa=? WHERE maTaiKhoan=?`,
          [expireDate, id]
        );
        return res.json({ success: true, message: `Đã khóa tài khoản ${days} ngày.` });
      }

      if (action === 'ban_forever') {
        await query(
          `UPDATE taikhoan SET trangThai=0, khoaVinhVien=1, thoiGianKhoa=NULL WHERE maTaiKhoan=?`,
          [id]
        );
        return res.json({ success: true, message: 'Đã khóa tài khoản vĩnh viễn.' });
      }

      if (action === 'unban') {
        await query(
          `UPDATE taikhoan SET trangThai=1, khoaVinhVien=0, thoiGianKhoa=NULL WHERE maTaiKhoan=?`,
          [id]
        );
        return res.json({ success: true, message: 'Đã mở khóa tài khoản.' });
      }

      // Cập nhật thông tin thông thường
      const safeRole = maVaiTro !== undefined
        ? ([1, 2].includes(Number(maVaiTro)) ? Number(maVaiTro) : null)
        : null;
      await query(
        `UPDATE taikhoan
         SET hoTen      = COALESCE(?, hoTen),
             email      = COALESCE(?, email),
             soDienThoai= COALESCE(?, soDienThoai),
             maVaiTro   = COALESCE(?, maVaiTro),
             trangThai  = COALESCE(?, trangThai)
         WHERE maTaiKhoan = ?`,
        [hoTen ?? null, email ?? null, soDienThoai ?? null, safeRole, trangThai ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật tài khoản thành công!' });
    } catch (err) { next(err); }
  },

  /**
   * DELETE /api/admin/users/:id — Xóa mềm tài khoản (trangThai = 0)
   * Không xóa khỏi DB, chỉ set trangThai = 0
   */
  softDeleteUser: async (req, res, next) => {
    try {
      const { id } = req.params;
      // Không cho phép xóa tài khoản admin
      const [user] = await query(`SELECT maVaiTro FROM taikhoan WHERE maTaiKhoan = ?`, [id]);
      if (user?.maVaiTro === 3)
        return res.status(403).json({ success: false, message: 'Không thể xóa tài khoản admin.' });
      await query(`UPDATE taikhoan SET trangThai = 0 WHERE maTaiKhoan = ?`, [id]);
      res.json({ success: true, message: 'Đã xóa tài khoản (có thể khôi phục lại).' });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ VOUCHER (TOÀN SÀN)
  // ══════════════════════════════════════════════════════════════════

  /**
   * GET /api/admin/vouchers
   * Trả về tất cả voucher kèm nguonVoucher để frontend phân loại
   */
  getVouchers: async (req, res, next) => {
    try {
      const rows = await query(`
        SELECT gg.maGiamGia AS id,
               gg.maVoucher AS code,
               gg.tenGiamGia AS title,
               gg.moTa AS description,
               gg.phanTramGiam AS discountPercent,
               gg.soLanToiDa AS maxUses,
               gg.thoiGianBatDau AS startsAt,
               gg.thoiGianKetThuc AS endsAt,
               gg.trangThai AS isActive,
               gg.maGianHang,
               gg.nguonVoucher,
               g.tenGianHang AS canteenName,
               (SELECT COUNT(*) FROM giamgia_daluu gd WHERE gd.maGiamGia = gg.maGiamGia) AS soLuotLuu
        FROM giamgia gg
        LEFT JOIN gianhang g ON g.maGianHang = gg.maGianHang
        HAVING (maxUses IS NULL OR soLuotLuu < maxUses)
        ORDER BY gg.nguonVoucher DESC, gg.maGiamGia DESC
      `);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /**
   * GET /api/admin/stores/list — lấy danh sách gian hàng (id + tên) để tạo voucher
   */
  getStoresList: async (req, res, next) => {
    try {
      const rows = await query(`SELECT maGianHang, tenGianHang FROM gianhang WHERE trangThai = 1 ORDER BY tenGianHang`);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /**
   * POST /api/admin/vouchers — Tạo voucher
   * maGianHang = null → toàn sàn, nguonVoucher = 'admin'
   * maGianHangList = [1,2,...] → áp nhiều gian hàng (tạo nhiều bản ghi)
   */
  createVoucher: async (req, res, next) => {
    try {
      const { code, title, description, discountPercent, maxUses, startsAt, endsAt, maGianHangList } = req.body;
      if (!code || !title || !discountPercent)
        return res.status(400).json({ success: false, message: 'Thiếu thông tin voucher.' });

      // maGianHangList = [] hoặc null → toàn sàn (1 bản ghi maGianHang=NULL)
      const storeIds = Array.isArray(maGianHangList) && maGianHangList.length > 0
        ? maGianHangList : [null];

      const insertedIds = [];
      for (const storeId of storeIds) {
        const r = await query(
          `INSERT INTO giamgia (maVoucher, tenGiamGia, moTa, phanTramGiam, soLanToiDa, thoiGianBatDau, thoiGianKetThuc, maGianHang, nguonVoucher, trangThai)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'admin', TRUE)`,
          [code, title, description || '', discountPercent, maxUses ?? null,
            startsAt ?? null, endsAt ?? null, storeId ?? null]
        );
        insertedIds.push(r.insertId);
      }
      res.status(201).json({ success: true, message: 'Tạo voucher thành công!', data: { ids: insertedIds } });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ success: false, message: 'Mã voucher đã tồn tại.' });
      next(err);
    }
  },

  /** PUT /api/admin/vouchers/:id */
  updateVoucher: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, description, discountPercent, maxUses, startsAt, endsAt, isActive } = req.body;
      await query(
        `UPDATE giamgia SET
           tenGiamGia     = COALESCE(?, tenGiamGia),
           moTa           = COALESCE(?, moTa),
           phanTramGiam   = COALESCE(?, phanTramGiam),
           soLanToiDa     = COALESCE(?, soLanToiDa),
           thoiGianBatDau = COALESCE(?, thoiGianBatDau),
           thoiGianKetThuc= COALESCE(?, thoiGianKetThuc),
           trangThai      = COALESCE(?, trangThai)
         WHERE maGiamGia = ?`,
        [title ?? null, description ?? null, discountPercent ?? null, maxUses ?? null,
        startsAt ?? null, endsAt ?? null, isActive ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật voucher thành công!' });
    } catch (err) { next(err); }
  },

  /**
   * DELETE /api/admin/vouchers/:id — Xóa mềm voucher (trangThai = 0)
   * Không xóa khỏi DB, chỉ vô hiệu hóa. Admin có thể kích hoạt lại qua Switch.
   */
  deleteVoucher: async (req, res, next) => {
    try {
      const { id } = req.params;
      // Xóa cứng: xóa cả trong danh sách đã lưu của user và bảng chính
      await query(`DELETE FROM giamgia_daluu WHERE maGiamGia = ?`, [id]);
      await query(`DELETE FROM giamgia WHERE maGiamGia = ?`, [id]);
      res.json({ success: true, message: 'Đã xóa vĩnh viễn voucher khỏi hệ thống.' });
    } catch (err) { next(err); }
  },

  /** POST /api/admin/stores/:id/banner — Upload ảnh banner gian hàng */
  uploadStoreBanner: async (req, res, next) => {
    try {
      const { id } = req.params;
      if (!req.file)
        return res.status(400).json({ success: false, message: 'Không có file ảnh!' });
      const buildUrl = (req, p) => (!p ? '' : p.startsWith('http') ? p : `${req.protocol}://${req.get('host')}${p}`);
      const { publicPath } = await saveCroppedDishImage(req.file.buffer);
      const imageUrl = buildUrl(req, publicPath);
      await query(`UPDATE gianhang SET banner = ? WHERE maGianHang = ?`, [publicPath, id]);
      res.json({ success: true, imageUrl, message: 'Cập nhật ảnh gian hàng thành công!' });
    } catch (err) { next(err); }
  },

  /** GET /api/admin/stores/:id/stats — Thống kê chi tiết gian hàng */
  getStoreStats: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { filter = 'month' } = req.query; // day, month, year

      const [storeRow] = await query(
        `SELECT g.maGianHang, g.tenGianHang, g.banner, g.trangThai, tk.hoTen AS tenChuQuan, tk.email
         FROM gianhang g LEFT JOIN taikhoan tk ON g.maTaiKhoan = tk.maTaiKhoan
         WHERE g.maGianHang = ?`, [id]
      );
      if (!storeRow) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });

      const [stats] = await query(
        `SELECT
          COUNT(DISTINCT d.maDonHang) AS tongDon,
          COALESCE(SUM(CASE WHEN d.trangThaiDonHang IN ('daGiao','choGiaoHang') THEN d.tongTien ELSE 0 END), 0) AS tongDoanhThu,
          COUNT(DISTINCT m.maMonAn) AS soMonAn,
          COALESCE(ROUND(AVG(dg.soSao), 1), 0) AS diemTrungBinh,
          COUNT(DISTINCT dg.maDanhGia) AS tongDanhGia
        FROM gianhang g
        LEFT JOIN monan m ON m.maGianHang = g.maGianHang AND m.daXoa = 0
        LEFT JOIN chitietdonhang ct ON ct.maMonAn = m.maMonAn
        LEFT JOIN donhang d ON d.maDonHang = ct.maDonHang
        LEFT JOIN danhgia dg ON dg.maMonAn = m.maMonAn
        WHERE g.maGianHang = ?`, [id]
      );

      let format = '%m/%Y';
      let period = '6 MONTH';
      if (filter === 'day') { format = '%d/%m'; period = '14 DAY'; }
      if (filter === 'year') { format = '%Y'; period = '5 YEAR'; }

      const chartData = await query(
        `SELECT DATE_FORMAT(d.thoiGianDat, ?) AS label,
                COUNT(DISTINCT d.maDonHang) AS tongDon,
                COALESCE(SUM(CASE WHEN d.trangThaiDonHang IN ('daGiao','choGiaoHang') THEN d.tongTien ELSE 0 END),0) AS doanhThu
         FROM donhang d
         JOIN chitietdonhang ct ON ct.maDonHang = d.maDonHang
         JOIN monan m ON m.maMonAn = ct.maMonAn
         WHERE m.maGianHang = ? AND d.thoiGianDat >= DATE_SUB(NOW(), INTERVAL ${period})
         GROUP BY label ORDER BY MIN(d.thoiGianDat) ASC`, [format, id]
      );

      const buildUrl = (req, p) => (!p ? '' : p.startsWith('http') ? p : `${req.protocol}://${req.get('host')}${p}`);
      res.json({
        success: true,
        data: {
          ...storeRow,
          banner: buildUrl(req, storeRow.banner),
          ...stats,
          chartData,
        }
      });
    } catch (err) { next(err); }
  },
};

module.exports = AdminController;
