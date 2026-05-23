const db = require('../config/db');

const UserModel = {
    // Lấy thông tin (Ẩn mật khẩu)
    findById: async (maTaiKhoan) => {
        const rows = await db.query(
            'SELECT maTaiKhoan, maVaiTro, tenDangNhap, hoTen, email, soDienThoai, trangThai, anhDaiDien FROM taiKhoan WHERE maTaiKhoan = ?', 
            [maTaiKhoan]
        );
        return rows[0];
    },

    // Cập nhật thông tin (Họ tên, SĐT)
    update: async (maTaiKhoan, data) => {
        const { hoTen, email, soDienThoai } = data;
        const hoTenSafe = hoTen !== undefined ? hoTen : null;
        const emailSafe = email !== undefined ? email : null;
        const soDienThoaiSafe = soDienThoai !== undefined ? soDienThoai : null;

        const result = await db.query(
            `UPDATE taiKhoan 
             SET hoTen = COALESCE(?, hoTen), 
                 email = COALESCE(?, email),
                 soDienThoai = COALESCE(?, soDienThoai)
             WHERE maTaiKhoan = ?`,
            [hoTenSafe, emailSafe, soDienThoaiSafe, maTaiKhoan]
        );
        return result.affectedRows > 0;
    },

    updateAvatar: async (maTaiKhoan, avatarPath) => {
        const result = await db.query(
            'UPDATE taiKhoan SET anhDaiDien = ? WHERE maTaiKhoan = ?',
            [avatarPath, maTaiKhoan]
        );
        return result.affectedRows > 0;
    }
};
module.exports = UserModel;