// routes/shipperRoutes.js
const express = require('express');
const router = express.Router();
const ShipperController = require('../controllers/shipperController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// Middleware: Tất cả các route dưới đây chỉ cho Role = 3 (Nhân viên giao hàng)
router.use(verifyToken);
router.use(authorizeRole([3])); 

// Xem danh sách nhóm đơn đang choGiaoHang
router.get('/groups/available', ShipperController.getAvailableGroups);

// Chi tiết 1 nhóm
router.get('/groups/:groupId', ShipperController.getGroupDetails);

// Shipper xác nhận nhận nhóm đơn
router.post('/groups/:groupId/accept', ShipperController.acceptGroupOrder);

// Shipper báo đã giao thành công / bị bom hàng (hủy)
router.put('/groups/:groupId/status', ShipperController.updateDeliveryStatus);

module.exports = router;
