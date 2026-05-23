// routes/canteenRoutes.js
const express = require('express');
const router = express.Router();
const GianHangController = require('../controllers/canteenController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');
const { handleDishImageUpload } = require('../config/upload');

// ==========================================
// 2. DÀNH CHO CHỦ QUÁN (Bắt buộc maVaiTro = 2)
// PHẢI khai báo TRƯỚC route /:id dynamic để Express không nhầm 'me' là id
// ==========================================
router.get('/me/info', verifyToken, authorizeRole([2]), GianHangController.getMyStore);
router.put('/me/info', verifyToken, authorizeRole([2]), GianHangController.updateMyStore);
router.post('/me/upload-banner', verifyToken, authorizeRole([2]), handleDishImageUpload, GianHangController.uploadBanner);

// Xem các đơn hàng (món ăn) cần chuẩn bị
router.get('/me/orders', verifyToken, authorizeRole([2]), GianHangController.getPendingOrders);
// Đánh dấu món đã xong
router.put('/me/orders/:itemId/status', verifyToken, authorizeRole([2]), GianHangController.markDishDone);

// ==========================================
// 1. DÀNH CHO KHÁCH HÀNG (Ai đăng nhập cũng xem được)
// ==========================================
router.get('/', verifyToken, GianHangController.getAllStores);
router.get('/:id', verifyToken, GianHangController.getStoreById);

module.exports = router;