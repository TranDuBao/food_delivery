// models/monAnModel.js
const db = require('../config/db');

const MonAnModel = {
    // 1. [KHÁCH HÀNG] Lấy tất cả món ăn chưa bị xóa
    getAll: async (keyword = '', limit = null, maDanhMuc = null) => {
        let sql = `
            SELECT m.maMonAn, m.maGianHang, m.maDanhMuc, m.tenMonAn, m.moTa, m.giaTien,
                   m.hinhAnh, m.trangThai, m.daXoa,
                   COALESCE(m.diemDanhGia, 0.0) as diemDanhGia,
                   COALESCE(m.luotDanhGia, 0)   as luotDanhGia,
                   COALESCE(m.soLuongDaBan, 0)  as soLuongDaBan,
                   COALESCE(m.soLuongTon, 99)   as soLuongTon,
                   d.tenDanhMuc, g.tenGianHang
            FROM monAn m
            LEFT JOIN danhmuc d ON m.maDanhMuc = d.maDanhMuc
            LEFT JOIN gianHang g ON m.maGianHang = g.maGianHang
            WHERE m.daXoa = 0 AND m.trangThai = 1 AND m.tenMonAn LIKE ?
        `;
        const params = [`%${keyword}%`];

        if (maDanhMuc) {
            sql += ' AND m.maDanhMuc = ?';
            params.push(Number(maDanhMuc));
        }

        if (limit) {
            sql += ' LIMIT ?';
            params.push(Number(limit));
        }

        const rows = await db.query(sql, params);
        return rows;
    },

    // 2. [KHÁCH HÀNG] Lấy chi tiết món ăn
    findById: async (maMonAn) => {
        const rows = await db.query(
            'SELECT * FROM monAn WHERE maMonAn = ? AND daXoa = 0 AND trangThai = 1',
            [maMonAn]
        );
        return rows[0];
    },

    // 3. [KHÁCH HÀNG / CHỦ QUÁN] Lấy danh sách món ăn theo mã gian hàng (chỉ đang bán)
    findByGianHang: async (maGianHang) => {
        const rows = await db.query(
            `SELECT m.*, COALESCE(m.soLuongTon, 99) as soLuongTon FROM monAn m
             WHERE m.maGianHang = ? AND m.daXoa = 0`,
            [maGianHang]
        );
        return rows;
    },

    // 3b. [CHỦ QUÁN] Lấy danh sách món đã bị xóa mềm (tab Ngừng bán)
    findByGianHangDeleted: async (maGianHang) => {
        const rows = await db.query(
            `SELECT m.*, COALESCE(m.soLuongTon, 99) as soLuongTon FROM monAn m
             WHERE m.maGianHang = ? AND m.daXoa = 1`,
            [maGianHang]
        );
        return rows;
    },

    // 4. Tìm maGianHang dựa vào maTaiKhoan
    getMaGianHangByTaiKhoan: async (maTaiKhoan) => {
        const rows = await db.query('SELECT maGianHang FROM gianHang WHERE maTaiKhoan = ?', [maTaiKhoan]);
        return rows[0] ? rows[0].maGianHang : null;
    },

    // 5. [CHỦ QUÁN] Thêm món ăn mới
    create: async (data) => {
        const { maGianHang, tenMonAn, giaTien, hinhAnh, trangThai, moTa, maDanhMuc, soLuongTon } = data;
        
        const hinhAnhSafe = hinhAnh !== undefined ? hinhAnh : null;
        const trangThaiSafe = trangThai !== undefined ? trangThai : 1;
        const moTaSafe = moTa !== undefined ? moTa : null;
        const maDanhMucSafe = maDanhMuc !== undefined ? maDanhMuc : null;
        const soLuongTonSafe = soLuongTon !== undefined ? Number(soLuongTon) : 99;

        const result = await db.query(
            `INSERT INTO monAn (maGianHang, maDanhMuc, tenMonAn, moTa, giaTien, hinhAnh, trangThai, daXoa, soLuongTon) 
             VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)`,
            [maGianHang, maDanhMucSafe, tenMonAn, moTaSafe, giaTien, hinhAnhSafe, trangThaiSafe, soLuongTonSafe]
        );
        return result.insertId;
    },

    // 6. [CHỦ QUÁN] Sửa món ăn
    update: async (maMonAn, maGianHang, data) => {
        const { tenMonAn, giaTien, hinhAnh, trangThai, moTa, soLuongTon } = data;
        
        const tenMonAnSafe = tenMonAn !== undefined ? tenMonAn : null;
        const giaTienSafe = giaTien !== undefined ? giaTien : null;
        const hinhAnhSafe = hinhAnh !== undefined ? hinhAnh : null;
        const trangThaiSafe = trangThai !== undefined ? trangThai : null;
        const moTaSafe = moTa !== undefined ? moTa : null;
        const soLuongTonSafe = soLuongTon !== undefined ? Number(soLuongTon) : null;

        const result = await db.query(
            `UPDATE monAn 
             SET tenMonAn = COALESCE(?, tenMonAn), 
                 giaTien = COALESCE(?, giaTien), 
                 hinhAnh = COALESCE(?, hinhAnh), 
                 trangThai = COALESCE(?, trangThai),
                 moTa = COALESCE(?, moTa),
                 soLuongTon = COALESCE(?, soLuongTon)
             WHERE maMonAn = ? AND maGianHang = ? AND daXoa = 0`,
            [tenMonAnSafe, giaTienSafe, hinhAnhSafe, trangThaiSafe, moTaSafe, soLuongTonSafe, maMonAn, maGianHang]
        );
        return result.affectedRows > 0;
    },

    // 7. [CHỦ QUÁN] Xóa mềm món ăn (daXoa = 1)
    softDelete: async (maMonAn, maGianHang) => {
        const result = await db.query(
            'UPDATE monAn SET daXoa = 1, soLuongTon = 0, trangThai = 0 WHERE maMonAn = ? AND maGianHang = ?',
            [maMonAn, maGianHang]
        );
        return result.affectedRows > 0;
    },

    // 8. [CHỦ QUÁN] Khôi phục món ăn đã xóa mềm (daXoa = 0)
    restore: async (maMonAn, maGianHang, soLuongTon = 0) => {
        const result = await db.query(
            'UPDATE monAn SET daXoa = 0, soLuongTon = ?, trangThai = CASE WHEN ? > 0 THEN 1 ELSE 0 END WHERE maMonAn = ? AND maGianHang = ?',
            [soLuongTon, soLuongTon, maMonAn, maGianHang]
        );
        return result.affectedRows > 0;
    },

    // 9. [ORDER] Kiểm tra tồn kho (dùng trong transaction)
    checkStock: async (connection, maMonAn) => {
        const [rows] = await connection.query(
            'SELECT soLuongTon, tenMonAn, daXoa, trangThai FROM monAn WHERE maMonAn = ?',
            [maMonAn]
        );
        return rows;
    },

    // 10. [ORDER] Trừ tồn kho (dùng trong transaction)
    decrementStock: async (connection, maMonAn, soLuong) => {
        const [result] = await connection.query(
            'UPDATE monAn SET soLuongTon = soLuongTon - ? WHERE maMonAn = ? AND soLuongTon >= ?',
            [soLuong, maMonAn, soLuong]
        );
        return result.affectedRows > 0;
    }
};

module.exports = MonAnModel;