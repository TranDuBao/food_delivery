// routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminCtrl = require('../controllers/adminController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');
const { handleDishImageUpload } = require('../config/upload');

// Tất cả route Admin đều yêu cầu đăng nhập + role = 3
const adminAuth = [verifyToken, authorizeRole([3])];

// ── Dashboard ──────────────────────────────────────────────────────
router.get('/dashboard', adminAuth, adminCtrl.getDashboard);
router.get('/monthly-stats', adminAuth, adminCtrl.getMonthlyStats);
router.get('/orders', adminAuth, adminCtrl.getOrders);
router.get('/revenue-by-store', adminAuth, adminCtrl.getRevenueByStore);

// ── Quản lý Gian hàng ─────────────────────────────────────────────
router.get('/stores', adminAuth, adminCtrl.getStores);
router.get('/stores/list', adminAuth, adminCtrl.getStoresList);
router.post('/stores', adminAuth, adminCtrl.createStore);
router.put('/stores/:id', adminAuth, adminCtrl.updateStore);
router.delete('/stores/:id', adminAuth, adminCtrl.deleteStore);
router.post('/stores/:id/banner', adminAuth, handleDishImageUpload, adminCtrl.uploadStoreBanner);
router.get('/stores/:id/stats', adminAuth, adminCtrl.getStoreStats);

// ── Quản lý Tài khoản ─────────────────────────────────────────────
router.get('/users', adminAuth, adminCtrl.getUsers);
router.post('/users', adminAuth, adminCtrl.createUser);
router.put('/users/:id', adminAuth, adminCtrl.updateUser);
router.delete('/users/:id', adminAuth, adminCtrl.softDeleteUser);  // Xóa mềm

// ── Quản lý Voucher (toàn sàn) ────────────────────────────────────
router.get('/vouchers', adminAuth, adminCtrl.getVouchers);
router.post('/vouchers', adminAuth, adminCtrl.createVoucher);
router.put('/vouchers/:id', adminAuth, adminCtrl.updateVoucher);
router.delete('/vouchers/:id', adminAuth, adminCtrl.deleteVoucher);

// ── Seed Admin đầu tiên (chỉ dùng 1 lần, gọi POST /api/admin/seed) ────────────
router.post('/seed', async (req, res) => {
  try {
    const bcrypt = require('bcrypt');
    const { query } = require('../config/db');
    const { password = 'Admin@123' } = req.body;
    const hash = await bcrypt.hash(password, 10);
    await query(
      `INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, maVaiTro, trangThai)
       VALUES ('admin', ?, 'Quan tri vien', 'admin@food.com', 3, 1)
       ON DUPLICATE KEY UPDATE maVaiTro = 3, trangThai = 1, matKhau = ?`,
      [hash, hash]
    );
    res.json({ success: true, message: 'Admin created! Login: admin / ' + password });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
