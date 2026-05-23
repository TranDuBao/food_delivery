const db = require('../config/db');

const addressController = {
    getAllAddresses: async (req, res) => {
        try {
            const buildings = await db.query('SELECT maToaNha, tenToaNha FROM toanha');
            const rooms = await db.query('SELECT maPhong, tenPhong, maToaNha FROM phong');
            
            res.status(200).json({
                success: true,
                data: {
                    buildings: buildings,
                    rooms: rooms
                }
            });
        } catch (error) {
            console.error('Error in getAllAddresses:', error);
            res.status(500).json({ success: false, message: 'Lỗi server khi lấy dữ liệu địa chỉ.' });
        }
    }
};

module.exports = addressController;
