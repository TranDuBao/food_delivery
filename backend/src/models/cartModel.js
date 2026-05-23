// models/cartModel.js
const db = require('../config/db');

const CartModel = {
    // 1. Lấy toàn bộ giỏ hàng của User (JOIN để lấy tên món, hình ảnh, tên quán)
    getCart: async (maTaiKhoan) => {
        const rows = await db.query(`
            SELECT g.maMonAn, g.soLuong, m.tenMonAn, m.giaTien, m.hinhAnh, gh.maGianHang, gh.tenGianHang
            FROM giohang g
            JOIN monan m ON g.maMonAn = m.maMonAn
            JOIN gianhang gh ON m.maGianHang = gh.maGianHang
            WHERE g.maTaiKhoan = ? AND m.daXoa = 0
        `, [maTaiKhoan]);
        return rows;
    },

    // 2. Thêm món vào giỏ (Nếu món đã có sẵn trong giỏ -> Cộng dồn số lượng)
    addToCart: async (maTaiKhoan, maMonAn, soLuong) => {
        const result = await db.query(`
            INSERT INTO giohang (maTaiKhoan, maMonAn, soLuong)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE soLuong = soLuong + ?
        `, [maTaiKhoan, maMonAn, soLuong, soLuong]);
        return result.affectedRows > 0;
    },

    // 3. Cập nhật số lượng (Dùng khi user bấm nút [+] hoặc [-] trong app)
    updateQuantity: async (maTaiKhoan, maMonAn, soLuong) => {
        const result = await db.query(
            'UPDATE giohang SET soLuong = ? WHERE maTaiKhoan = ? AND maMonAn = ?', 
            [soLuong, maTaiKhoan, maMonAn]
        );
        return result.affectedRows > 0;
    },

    // 4. Xóa 1 món cụ thể khỏi giỏ
    removeItem: async (maTaiKhoan, maMonAn) => {
        const result = await db.query(
            'DELETE FROM giohang WHERE maTaiKhoan = ? AND maMonAn = ?', 
            [maTaiKhoan, maMonAn]
        );
        return result.affectedRows > 0;
    },

    // 5. Xóa trắng giỏ hàng (Dùng khi User đổi ý, hoặc sau khi Đặt Hàng thành công)
    clearCart: async (maTaiKhoan) => {
        const result = await db.query(
            'DELETE FROM giohang WHERE maTaiKhoan = ?', 
            [maTaiKhoan]
        );
        return result.affectedRows > 0;
    }
};

module.exports = CartModel;