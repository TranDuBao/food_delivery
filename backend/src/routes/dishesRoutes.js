// routes/monAnRoutes.js
const express = require('express');
const router = express.Router();
const MonAnController = require('../controllers/dishesController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');
const { handleDishImageUpload } = require('../config/upload');

// ==========================================
// 1. DÀNH CHO CHỦ QUÁN - Routes static PHẢI đặt TRƯỚC /:id
// ==========================================
router.get('/me/menu/deleted', verifyToken, authorizeRole([2]), MonAnController.getDeletedMenu); // Tab Ngừng bán
router.get('/me/menu', verifyToken, authorizeRole([2]), MonAnController.getMyMenu);
router.post('/me/menu/upload-image', verifyToken, authorizeRole([2]), handleDishImageUpload, MonAnController.uploadDishImage);
router.post('/me/menu', verifyToken, authorizeRole([2]), MonAnController.addFood);
router.put('/me/menu/:id', verifyToken, authorizeRole([2]), MonAnController.updateFood);
router.put('/me/menu/:id/restore', verifyToken, authorizeRole([2]), MonAnController.restoreFood); // Khôi phục
router.delete('/me/menu/:id', verifyToken, authorizeRole([2]), MonAnController.deleteFood);

// ==========================================
// 2. DÀNH CHO KHÁCH HÀNG - Routes dynamic /:id đặt SAU
// ==========================================
router.get('/gian-hang/:gianHangId', verifyToken, MonAnController.getFoodsByGianHang);
router.get('/', verifyToken, MonAnController.getAllFoods);
router.get('/:id', verifyToken, MonAnController.getFoodById);

module.exports = router;