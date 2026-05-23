const express = require('express');
const router = express.Router();
const OrderController = require('../controllers/orderController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

router.use(verifyToken);

// Khách hàng (role 1)
router.post('/checkout', authorizeRole([1]), OrderController.checkout);           // Đặt hàng
router.get('/area-orders', authorizeRole([1]), OrderController.getAreaOrders);    // Đơn cùng khu vực
router.get('/my', authorizeRole([1]), OrderController.getMyOrders);               // Lịch sử đơn của tôi
router.post('/my/:id/cancel', authorizeRole([1]), OrderController.cancelOrder);   // Hủy đơn hàng

// Nhân viên gian hàng (role 2)
router.get('/staff-pending', authorizeRole([2]), OrderController.getStaffOrders); // Đơn cần chuẩn bị
router.put('/:id/start', authorizeRole([2]), OrderController.startPreparing);     // Bắt đầu làm
router.put('/:id/ready', authorizeRole([2]), OrderController.markOrderReady);     // Đánh dấu xong
router.get('/staff-kds', authorizeRole([2]), OrderController.getStaffKDS);        // Lấy danh sách gom món KDS
router.put('/staff-kds/:dishId/swipe', authorizeRole([2]), OrderController.swipeKDSItem); // Đánh dấu món đã nấu xong
router.get('/staff-statistics', authorizeRole([2]), OrderController.getStatistics); // Thống kê

// ── Delivery Trip (Tab Ship) ─────────────────────────────────────────────────
router.get('/staff-ready-items', authorizeRole([2]), OrderController.getReadyItems);                   // Lấy món đang ready
router.post('/staff-start-trip', authorizeRole([2]), OrderController.startDeliveryTrip);              // Bắt đầu chuyến giao
router.put('/staff-complete-item/:itemId', authorizeRole([2]), OrderController.completeDeliveryItem);       // Hoàn tất giao 1 món
router.get('/staff-active-trip', authorizeRole([2]), OrderController.getActiveTrip);                  // Chuyến đang giao

module.exports = router;
