const express = require('express');
const router = express.Router();
const CartController = require('../controllers/cartController');
const { verifyToken } = require('../middleware/authMiddleware');

// Tất cả thao tác với giỏ hàng đều bắt buộc User phải đăng nhập (Có Token)
router.use(verifyToken);

router.get('/', CartController.getCart);                    // Xem giỏ hàng
router.post('/add', CartController.addToCart);              // Thêm món
router.put('/update', CartController.updateQuantity);       // Cập nhật số lượng
router.delete('/remove/:id', CartController.removeItem);    // Xóa 1 món
router.delete('/clear', CartController.clearCart);          // Xóa toàn bộ giỏ

module.exports = router;