const UserModel = require('../models/customerModel');
const { query } = require('../config/db');

// ── Voucher helpers ───────────────────────────────────────────────────────────
// Bảng giamgia dùng maGianHang (FK → gianhang) và maMonAn (FK → monan)
async function ensureUserSavedVouchersTable() {
    await query(`
        CREATE TABLE IF NOT EXISTS giamgia_daluu (
            maGiamGiaDaLuu INT AUTO_INCREMENT PRIMARY KEY,
            maTaiKhoan     INT NOT NULL,
            maGiamGia      INT NOT NULL,
            thoiGianLuu    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_user_giamgia (maTaiKhoan, maGiamGia)
        )
    `).catch(() => { });
}

const UserController = {
    getProfile: async (req, res, next) => {
        try {
            const user = await UserModel.findById(req.user.maTaiKhoan);
            if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });

            // Map data to expected frontend keys
            const payload = {
                ...user,
                fullName: user.hoTen,
                name: user.tenDangNhap,
                email: user.email || '',
                phone: user.soDienThoai,
                avatarUrl: user.anhDaiDien ? (user.anhDaiDien.startsWith('http') ? user.anhDaiDien : `${req.protocol}://${req.get('host')}${user.anhDaiDien}`) : ''
            };

            res.status(200).json({ success: true, data: payload });
        } catch (error) { next(error); }
    },

    updateProfile: async (req, res, next) => {
        try {
            await UserModel.update(req.user.maTaiKhoan, req.body);
            res.status(200).json({ success: true, message: 'Cập nhật thông tin thành công!' });
        } catch (error) { next(error); }
    },

    uploadAvatar: async (req, res, next) => {
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'Không tìm thấy file ảnh' });
            }

            const avatarUrl = `/img/anhdaidien/${req.file.filename}`;
            await UserModel.updateAvatar(req.user.maTaiKhoan, avatarUrl);

            res.status(200).json({
                success: true,
                message: 'Tải ảnh đại diện thành công',
                avatarUrl: `${req.protocol}://${req.get('host')}${avatarUrl}`
            });
        } catch (error) { next(error); }
    },

    // ── Voucher endpoints ─────────────────────────────────────────────────────

    /** GET /api/promotions  — tất cả voucher đang active (khách hàng xem) */
    getAvailableVouchers: async (req, res, next) => {
        try {
            const rows = await query(`
                SELECT
                    gg.maGiamGia                AS id,
                    gg.maGianHang               AS canteenId,
                    g.tenGianHang               AS canteenName,
                    gg.maMonAn                  AS dishId,
                    m.tenMonAn                  AS dishName,
                    m.maDanhMuc                 AS categoryName,
                    gg.maVoucher                AS code,
                    gg.tenGiamGia               AS title,
                    gg.moTa                     AS description,
                    gg.phanTramGiam             AS discountPercent,
                    gg.hinhAnhBanner            AS bannerImageUrl,
                    gg.thoiGianBatDau           AS startsAt,
                    gg.thoiGianKetThuc          AS endsAt,
                    gg.trangThai                AS isActive,
                    gg.soLanToiDa               AS maxUses
                FROM giamgia gg
                INNER JOIN gianhang g ON g.maGianHang = gg.maGianHang
                LEFT  JOIN monan    m ON m.maMonAn    = gg.maMonAn
                WHERE gg.trangThai = TRUE
                  AND (gg.thoiGianBatDau IS NULL OR gg.thoiGianBatDau <= NOW())
                  AND (gg.thoiGianKetThuc IS NULL OR gg.thoiGianKetThuc >= NOW())
                ORDER BY gg.thoiGianTao DESC
            `);
            res.json(rows);
        } catch (error) { next(error); }
    },

    /** GET /api/promotions/my  — voucher đã lưu của user hiện tại */
    getMySavedVouchers: async (req, res, next) => {
        try {
            await ensureUserSavedVouchersTable();
            const userId = req.user.maTaiKhoan;
            const rows = await query(`
                SELECT
                    gd.maGiamGiaDaLuu           AS id,
                    gd.maGiamGia               AS promotionId,
                    gd.thoiGianLuu             AS savedAt,
                    gg.maGianHang              AS canteenId,
                    g.tenGianHang              AS canteenName,
                    gg.maMonAn                 AS dishId,
                    m.tenMonAn                 AS dishName,
                    m.maDanhMuc                AS categoryName,
                    gg.maVoucher               AS code,
                    gg.tenGiamGia              AS title,
                    gg.moTa                    AS description,
                    gg.phanTramGiam            AS discountPercent,
                    gg.hinhAnhBanner           AS bannerImageUrl,
                    gg.thoiGianBatDau          AS startsAt,
                    gg.thoiGianKetThuc         AS endsAt,
                    gg.trangThai               AS isActive,
                    gg.soLanToiDa              AS maxUses
                FROM giamgia_daluu gd
                INNER JOIN giamgia gg ON gg.maGiamGia = gd.maGiamGia
                INNER JOIN gianhang g ON g.maGianHang = gg.maGianHang
                LEFT  JOIN monan   m ON m.maMonAn    = gg.maMonAn
                WHERE gd.maTaiKhoan = ?
                ORDER BY gd.thoiGianLuu DESC
            `, [userId]);
            res.json(rows);
        } catch (error) { next(error); }
    },

    /** POST /api/promotions/my/:promotionId  — lưu voucher */
    saveVoucher: async (req, res, next) => {
        try {
            await ensureUserSavedVouchersTable();
            const userId = req.user.maTaiKhoan;
            const promotionId = Number(req.params.promotionId);
            if (!Number.isInteger(promotionId) || promotionId <= 0) {
                return res.status(400).json({ message: 'Voucher không hợp lệ.' });
            }
            // Kiểm tra voucher tồn tại, còn hiệu lực và còn lượt dùng
            const promos = await query(`
                SELECT gg.maGiamGia, gg.soLanToiDa,
                       (SELECT COUNT(*) FROM giamgia_daluu gd WHERE gd.maGiamGia = gg.maGiamGia) AS soLuotLuu
                FROM giamgia gg
                WHERE gg.maGiamGia = ? AND gg.trangThai = TRUE
                  AND (gg.thoiGianKetThuc IS NULL OR gg.thoiGianKetThuc >= NOW())
                LIMIT 1
            `, [promotionId]);

            if (promos.length === 0) {
                return res.status(404).json({ message: 'Voucher không tồn tại hoặc đã hết hạn.' });
            }
            const p = promos[0];
            if (p.soLanToiDa !== null && p.soLuotLuu >= p.soLanToiDa) {
                return res.status(400).json({ message: 'Voucher đã hết lượt sử dụng.' });
            }
            await query(`
                INSERT INTO giamgia_daluu (maTaiKhoan, maGiamGia)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE thoiGianLuu = CURRENT_TIMESTAMP
            `, [userId, promotionId]);
            res.json({ message: 'Đã lưu voucher.' });
        } catch (error) { next(error); }
    },

    /** DELETE /api/promotions/my/:promotionId  — xoá voucher đã lưu */
    removeSavedVoucher: async (req, res, next) => {
        try {
            await ensureUserSavedVouchersTable();
            const userId = req.user.maTaiKhoan;
            const promotionId = Number(req.params.promotionId);
            if (!Number.isInteger(promotionId) || promotionId <= 0) {
                return res.status(400).json({ message: 'Voucher không hợp lệ.' });
            }
            await query(`
                DELETE FROM giamgia_daluu
                WHERE maTaiKhoan = ? AND maGiamGia = ?
            `, [userId, promotionId]);
            res.json({ message: 'Đã xoá voucher.' });
        } catch (error) { next(error); }
    },

    /**
     * POST /api/promotions/apply
     * Body: { maGiamGia?, maVoucher?, tongTien, maGianHang, maMonAn? }
     * Validate voucher trước khi checkout. Không trừ lượt ở bước này.
     */
    applyVoucher: async (req, res, next) => {
        try {
            const { maGiamGia, maVoucher, tongTien, maGianHang, maMonAn } = req.body;

            if (!maGiamGia && !maVoucher) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập mã voucher.' });
            }
            if (!tongTien || tongTien <= 0) {
                return res.status(400).json({ success: false, message: 'Tổng tiền không hợp lệ.' });
            }

            // Tìm voucher theo id hoặc mã code
            let whereClause = 'maGiamGia = ?';
            let whereParam = maGiamGia;
            if (!maGiamGia && maVoucher) {
                whereClause = 'UPPER(maVoucher) = UPPER(?)';
                whereParam = maVoucher.toString().trim();
            }

            const [voucher] = await query(`
                SELECT maGiamGia, tenGiamGia, moTa, phanTramGiam,
                       soLanToiDa, soLanDaDung,
                       thoiGianBatDau, thoiGianKetThuc,
                       trangThai, maGianHang AS voucherCanteenId,
                       maMonAn AS voucherDishId
                FROM giamgia
                WHERE ${whereClause}
                LIMIT 1
            `, [whereParam]);

            if (!voucher) {
                return res.status(404).json({ success: false, message: 'Mã voucher không tồn tại.' });
            }

            // ── 1. Kiểm tra trạng thái active ──────────────────────────────
            if (!voucher.trangThai) {
                return res.status(400).json({ success: false, message: 'Voucher đã bị vô hiệu hoá.' });
            }

            // ── 2. Kiểm tra thời hạn ────────────────────────────────────────
            const now = new Date();
            if (voucher.thoiGianBatDau && new Date(voucher.thoiGianBatDau) > now) {
                return res.status(400).json({ success: false, message: 'Voucher chưa đến thời gian áp dụng.' });
            }
            if (voucher.thoiGianKetThuc && new Date(voucher.thoiGianKetThuc) < now) {
                return res.status(400).json({ success: false, message: 'Voucher đã hết hạn sử dụng.' });
            }

            // ── 3. Kiểm tra số lượt còn lại ────────────────────────────────
            if (voucher.soLanToiDa !== null && voucher.soLanDaDung >= voucher.soLanToiDa) {
                return res.status(400).json({
                    success: false,
                    message: `Voucher đã hết lượt sử dụng (${voucher.soLanDaDung}/${voucher.soLanToiDa}).`
                });
            }

            // ── 4. Kiểm tra áp dụng đúng quán ──────────────────────────────
            if (maGianHang && voucher.voucherCanteenId && Number(maGianHang) !== Number(voucher.voucherCanteenId)) {
                return res.status(400).json({ success: false, message: 'Voucher này không áp dụng cho quán bạn đang chọn.' });
            }

            // ── 5. Kiểm tra áp dụng đúng món ───────────────────────────────
            if (voucher.voucherDishId && maMonAn && Number(maMonAn) !== Number(voucher.voucherDishId)) {
                return res.status(400).json({ success: false, message: 'Voucher này chỉ áp dụng cho món ăn cụ thể.' });
            }

            // ── 6. Tính số tiền giảm ────────────────────────────────────────
            const discount = voucher.phanTramGiam
                ? Math.round((Number(tongTien) * Number(voucher.phanTramGiam)) / 100)
                : 0;
            const finalAmount = Math.max(0, Number(tongTien) - discount);

            return res.json({
                success: true,
                data: {
                    maGiamGia: voucher.maGiamGia,
                    tenGiamGia: voucher.tenGiamGia,
                    phanTramGiam: voucher.phanTramGiam,
                    soTienGiam: discount,
                    tongTienSauGiam: finalAmount,
                    luotConLai: voucher.soLanToiDa !== null
                        ? voucher.soLanToiDa - voucher.soLanDaDung
                        : null,
                }
            });
        } catch (error) { next(error); }
    },

    // ── Thống kê cá nhân ──────────────────────────────────────────────────────
    /** GET /api/customer/stats */
    getMyStats: async (req, res, next) => {
        try {
            const uid = req.user.maTaiKhoan;
            const rows = await query(`
                SELECT
                    COUNT(*) AS tongDonHang,
                    COALESCE(SUM(tongTien), 0) AS tongChiTieu
                FROM donhang
                WHERE maTaiKhoan = ? AND trangThaiDonHang = 'daGiao'
            `, [uid]);
            const total = rows[0] || { tongDonHang: 0, tongChiTieu: 0 };

            const monthly = await query(`
                SELECT
                    DATE_FORMAT(thoiGianDat, '%Y-%m') AS thang,
                    DATE_FORMAT(thoiGianDat, '%m/%Y')  AS label,
                    COALESCE(SUM(tongTien), 0)          AS tongTien,
                    COUNT(*)                            AS soDon
                FROM donhang
                WHERE maTaiKhoan = ?
                  AND trangThaiDonHang = 'daGiao'
                  AND thoiGianDat >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
                GROUP BY DATE_FORMAT(thoiGianDat, '%Y-%m')
                ORDER BY thang ASC
            `, [uid]);

            res.json({ success: true, data: { ...total, monthly } });
        } catch (error) { next(error); }
    },

    // ── Ví cá nhân ────────────────────────────────────────────────────────────
    /** GET /api/customer/wallet */
    getWallet: async (req, res, next) => {
        try {
            const uid = req.user.maTaiKhoan;
            await ensureWalletTables();
            await query(`INSERT IGNORE INTO vi_ca_nhan (maTaiKhoan, soDu) VALUES (?, 0)`, [uid]);
            const [wallet] = await query(`SELECT id, soDu, capNhatLuc FROM vi_ca_nhan WHERE maTaiKhoan = ?`, [uid]);
            const txs = await query(`
                SELECT id, loai, soTien, trangThai, nganHang, soTaiKhoanNH, tenChuTK,
                       maGiaoDich, ghiChu, thoiGian
                FROM giao_dich_vi WHERE maTaiKhoan = ?
                ORDER BY thoiGian DESC LIMIT 30
            `, [uid]);
            res.json({ success: true, data: { wallet, transactions: txs } });
        } catch (error) { next(error); }
    },

    /** POST /api/customer/wallet/deposit */
    depositWallet: async (req, res, next) => {
        try {
            const uid = req.user.maTaiKhoan;
            const soTien = Number(req.body.soTien);
            if (!soTien || soTien < 10000)
                return res.status(400).json({ success: false, message: 'Số tiền tối thiểu là 10.000đ' });

            await ensureWalletTables();
            await query(`INSERT IGNORE INTO vi_ca_nhan (maTaiKhoan, soDu) VALUES (?, 0)`, [uid]);

            const maGiaoDich = `NAP${uid}${Date.now()}`;
            await query(`
                INSERT INTO giao_dich_vi (maTaiKhoan, loai, soTien, trangThai, maGiaoDich, ghiChu)
                VALUES (?, 'nap', ?, 'cho_xu_ly', ?, 'Nạp tiền qua chuyển khoản ngân hàng')
            `, [uid, soTien, maGiaoDich]);

            res.json({
                success: true,
                data: {
                    maGiaoDich,
                    soTien,
                    nganHang: 'MB Bank',
                    soTaiKhoan: '0353205835',
                    tenChuTK: 'SHIP FOOD APP',
                    noiDungCK: maGiaoDich,
                }
            });
        } catch (error) { next(error); }
    },

    /** POST /api/customer/wallet/withdraw */
    withdrawWallet: async (req, res, next) => {
        try {
            const uid = req.user.maTaiKhoan;
            const { soTien, nganHang, soTaiKhoanNH, tenChuTK } = req.body;
            const amount = Number(soTien);
            if (!amount || amount < 10000)
                return res.status(400).json({ success: false, message: 'Số tiền tối thiểu là 10.000đ' });
            if (!nganHang || !soTaiKhoanNH || !tenChuTK)
                return res.status(400).json({ success: false, message: 'Vui lòng điền đầy đủ thông tin ngân hàng.' });

            await ensureWalletTables();
            const [wallet] = await query(`SELECT soDu FROM vi_ca_nhan WHERE maTaiKhoan = ?`, [uid]);
            if (!wallet || parseFloat(wallet.soDu) < amount)
                return res.status(400).json({ success: false, message: 'Số dư không đủ để thực hiện giao dịch.' });

            const maGiaoDich = `RUT${uid}${Date.now()}`;
            const conn = (await require('../config/db').getPool().getConnection());
            try {
                await conn.beginTransaction();
                await conn.execute(`UPDATE vi_ca_nhan SET soDu = soDu - ? WHERE maTaiKhoan = ?`, [amount, uid]);
                await conn.execute(`
                    INSERT INTO giao_dich_vi
                        (maTaiKhoan, loai, soTien, soDuTruoc, soDuSau, trangThai,
                         nganHang, soTaiKhoanNH, tenChuTK, maGiaoDich, ghiChu)
                    VALUES (?, 'rut', ?, ?, ?, 'cho_xu_ly', ?, ?, ?, ?, 'Yêu cầu rút tiền')
                `, [uid, amount, parseFloat(wallet.soDu),
                    parseFloat(wallet.soDu) - amount,
                    nganHang, soTaiKhoanNH, tenChuTK, maGiaoDich]);
                await conn.commit();
            } catch (e) { await conn.rollback(); throw e; }
            finally { conn.release(); }

            res.json({ success: true, message: 'Yêu cầu rút tiền đã được ghi nhận. Xử lý trong 1-3 ngày làm việc.' });
        } catch (error) { next(error); }
    },
};

// ── Wallet helper ──────────────────────────────────────────────────────────────
async function ensureWalletTables() {
    await query(`
        CREATE TABLE IF NOT EXISTS vi_ca_nhan (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            maTaiKhoan  INT NOT NULL UNIQUE,
            soDu        DECIMAL(15,2) DEFAULT 0.00,
            capNhatLuc  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    `).catch(() => { });
    await query(`
        CREATE TABLE IF NOT EXISTS giao_dich_vi (
            id            INT AUTO_INCREMENT PRIMARY KEY,
            maTaiKhoan    INT NOT NULL,
            loai          ENUM('nap','rut','thanh_toan','hoan_tien') NOT NULL,
            soTien        DECIMAL(15,2) NOT NULL,
            soDuTruoc     DECIMAL(15,2),
            soDuSau       DECIMAL(15,2),
            trangThai     ENUM('cho_xu_ly','hoan_thanh','that_bai') DEFAULT 'cho_xu_ly',
            nganHang      VARCHAR(50),
            soTaiKhoanNH  VARCHAR(50),
            tenChuTK      VARCHAR(100),
            maGiaoDich    VARCHAR(100),
            ghiChu        TEXT,
            thoiGian      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `).catch(() => { });
}

module.exports = UserController;
