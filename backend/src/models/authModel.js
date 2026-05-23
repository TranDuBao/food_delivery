// models/auth.model.js
const db = require('../config/db'); 

const AuthModel = {
    // Tìm tài khoản theo tên đăng nhập
    findByUsername: async (tenDangNhap) => {
        const rows = await db.query(
            'SELECT * FROM taiKhoan WHERE tenDangNhap = ?',
            [tenDangNhap]
        );
        return rows[0]; // Trả về user đầu tiên hoặc undefined
    },

    // Tìm tài khoản theo email
    findByEmail: async (email) => {
        const rows = await db.query(
            'SELECT * FROM taiKhoan WHERE email = ?',
            [email]
        );
        return rows[0];
    },

    // [SOCIAL LOGIN] Tìm hoặc tạo tài khoản từ Google/Facebook
    findOrCreateSocialAccount: async ({ email, hoTen, provider, providerId, anhDaiDien }) => {
        // 1. Tìm bằng email
        let rows = await db.query(
            'SELECT * FROM taiKhoan WHERE email = ? AND trangThai = 1',
            [email]
        );
        if (rows[0]) return rows[0];

        // 2. Tạo tài khoản mới — tenDangNhap = provider_providerId
        const tenDangNhap = `${provider}_${providerId}`;
        const result = await db.query(
            `INSERT INTO taiKhoan (maVaiTro, tenDangNhap, matKhau, hoTen, email, trangThai, anhDaiDien) 
             VALUES (1, ?, '', ?, ?, 1, ?)`,
            [tenDangNhap, hoTen, email, anhDaiDien || null]
        );
        const newId = result.insertId;
        rows = await db.query('SELECT * FROM taiKhoan WHERE maTaiKhoan = ?', [newId]);
        return rows[0];
    },

    // Tìm tài khoản theo số điện thoại (dành cho quên mật khẩu)
    findByPhone: async (soDienThoai) => {
        const rows = await db.query(
            'SELECT * FROM taiKhoan WHERE soDienThoai = ?',
            [soDienThoai]
        );
        return rows[0];
    },

    // Tạo tài khoản mới (Mặc định maVaiTro = 1 là Khách hàng)
    createAccount: async (data) => {
        const { tenDangNhap, matKhauHash, hoTen, email, soDienThoai } = data;
        const result = await db.query(
            `INSERT INTO taiKhoan (maVaiTro, tenDangNhap, matKhau, hoTen, email, soDienThoai, trangThai) 
             VALUES (1, ?, ?, ?, ?, ?, 1)`,
            [tenDangNhap, matKhauHash, hoTen, email || null, soDienThoai]
        );
        return result.insertId;
    },

    // Cập nhật mật khẩu mới
    updatePassword: async (maTaiKhoan, matKhauHash) => {
        const result = await db.query(
            'UPDATE taiKhoan SET matKhau = ? WHERE maTaiKhoan = ?',
            [matKhauHash, maTaiKhoan]
        );
        return result.affectedRows > 0;
    }
};

module.exports = AuthModel;