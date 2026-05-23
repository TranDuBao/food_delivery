// models/shipperModel.js
const db = require('../config/db');

const ShipperModel = {
    // 1. Xem danh sách nhóm đơn đang choGiaoHang (chưa ai nhận)
    getAvailableGroups: async () => {
        const rows = await db.query(
            `SELECT n.maNhomGiaoHang, tn.tenToaNha, n.thoiGianTaoNhom 
             FROM nhomgiaohang n
             LEFT JOIN toanha tn ON n.maToaNha = tn.maToaNha
             WHERE n.trangThaiNhom = 'choGiaoHang' AND n.maNhanVienGiaoHang IS NULL`
        );
        return rows;
    },

    // 2. Lấy thông tin chi tiết một nhóm (các đơn bên trong)
    getGroupDetails: async (maNhomGiaoHang) => {
        const rows = await db.query(
            `SELECT d.maDonHang, tn.tenToaNha, p.tenPhong, d.tongTien, t.hoTen, t.soDienThoai
             FROM donhang d
             JOIN taikhoan t ON d.maTaiKhoan = t.maTaiKhoan
             LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
             LEFT JOIN phong p ON d.maPhong = p.maPhong
             WHERE d.maNhomGiaoHang = ?`,
            [maNhomGiaoHang]
        );
        return rows;
    },

    // 3. Nhận đơn (Shipper bấm Nhận)
    acceptGroup: async (maNhomGiaoHang, maNhanVienGiaoHang) => {
        const result = await db.query(
            `UPDATE nhomgiaohang SET maNhanVienGiaoHang = ?, trangThaiNhom = 'dangGiao' 
             WHERE maNhomGiaoHang = ? AND trangThaiNhom = 'choGiaoHang'`,
            [maNhanVienGiaoHang, maNhomGiaoHang]
        );
        if (result.affectedRows > 0) {
            // Cập nhật donhang bên trong
            await db.query(`UPDATE donhang SET trangThaiDonHang = 'dangGiao' WHERE maNhomGiaoHang = ?`, [maNhomGiaoHang]);
            return true;
        }
        return false;
    },

    // 4. Lấy danh sách nhóm do mình đang giao
    getMyActiveGroups: async (maNhanVienGiaoHang) => {
        const rows = await db.query(
            `SELECT n.*, tn.tenToaNha 
             FROM nhomgiaohang n
             LEFT JOIN toanha tn ON n.maToaNha = tn.maToaNha
             WHERE n.maNhanVienGiaoHang = ? AND n.trangThaiNhom = 'dangGiao'`,
            [maNhanVienGiaoHang]
        );
        return rows;
    },

    // 5. Cập nhật trạng thái nhận/hủy của một nhóm
    updateGroupStatus: async (maNhomGiaoHang, maNhanVienGiaoHang, status) => {
        // status param: 'daGiao' hoặc 'daHuy'
        const finalStatusForGroup = status === 'daGiao' ? 'hoanThanh' : 'daHuy';

        const result = await db.query(
            `UPDATE nhomgiaohang SET trangThaiNhom = ? 
              WHERE maNhomGiaoHang = ? AND maNhanVienGiaoHang = ? AND trangThaiNhom = 'dangGiao'`,
            [finalStatusForGroup, maNhomGiaoHang, maNhanVienGiaoHang]
        );

        if (result.affectedRows > 0) {
            await db.query(`UPDATE donhang SET trangThaiDonHang = ? WHERE maNhomGiaoHang = ?`, [status, maNhomGiaoHang]);
            return true;
        }
        return false;
    }
};

module.exports = ShipperModel;
