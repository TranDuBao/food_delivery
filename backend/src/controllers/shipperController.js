// controllers/shipperController.js
const ShipperModel = require('../models/shipperModel');

const ShipperController = {
    // Xem danh sách nhóm đơn đang chờ người giao
    getAvailableGroups: async (req, res, next) => {
        try {
            const groups = await ShipperModel.getAvailableGroups();
            res.status(200).json({ success: true, data: groups });
        } catch (error) {
            next(error);
        }
    },

    // Lấy chi tiết của một nhóm
    getGroupDetails: async (req, res, next) => {
        try {
            const { groupId } = req.params;
            const details = await ShipperModel.getGroupDetails(groupId);
            res.status(200).json({ success: true, data: details });
        } catch (error) {
            next(error);
        }
    },

    // Bấm nhận 1 nhóm giao
    acceptGroupOrder: async (req, res, next) => {
        try {
            const maNhanVienGiaoHang = req.user.maTaiKhoan;
            const { groupId } = req.params;

            const success = await ShipperModel.acceptGroup(groupId, maNhanVienGiaoHang);
            if (!success) {
                return res.status(400).json({ success: false, message: 'Nhóm đơn này đã có người nhận hoặc không hợp lệ!' });
            }

            res.status(200).json({ success: true, message: 'Nhận đơn thành công!' });
        } catch (error) {
             next(error);
        }
    },

    // Cập nhật trạng thái sau khi giao (Hoàn thành hoặc Bom hàng)
    updateDeliveryStatus: async (req, res, next) => {
        try {
            const maNhanVienGiaoHang = req.user.maTaiKhoan;
            const { groupId } = req.params;
            const { status } = req.body; // 'daGiao' hoặc 'daHuy'

            if (!['daGiao', 'daHuy'].includes(status)) {
                return res.status(400).json({ success: false, message: 'Trạng thái không hợp lệ' });
            }

            const success = await ShipperModel.updateGroupStatus(groupId, maNhanVienGiaoHang, status);
            if (!success) {
                 return res.status(400).json({ success: false, message: 'Cập nhật thất bại, bạn không phải người phụ trách đơn này hoặc nhóm này không còn đang giao.'});
            }

            res.status(200).json({ success: true, message: 'Cập nhật trạng thái giao hàng thành công!' });
        } catch (error) {
            next(error);
        }
    }
};

module.exports = ShipperController;
