// routes/auth.routes.js
const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// Các route Public (Không cần token)
router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/social-login', AuthController.socialLogin);   // Google / Facebook
router.post('/forgot-password', AuthController.forgotPassword);
router.post('/logout', AuthController.logout);

// 1. Route chỉ cần đăng nhập (Ai cũng gọi được)
router.get('/profile', verifyToken, (req, res) => {
    res.json({ message: `Chào user có ID: ${req.user.maTaiKhoan}` });
});

// 2. Route yêu cầu phân quyền (Chỉ Nhân viên căn tin - maVaiTro = 2 mới được vào)
router.post('/add-food', verifyToken, authorizeRole([2]), (req, res) => {
    res.json({ message: 'Đây là khu vực thêm món ăn của căn tin' });
});

module.exports = router;