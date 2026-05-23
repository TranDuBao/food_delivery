// routes/promotionRoutes.js
const express = require('express');
const router = express.Router();
const staffCtrl = require('../controllers/staffController');
const customerCtrl = require('../controllers/customerController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// ── Staff CRUD (role 2) ──────────────────────────────────────────────────────
router.get('/staff', verifyToken, authorizeRole([2]), staffCtrl.getPromotions);
router.post('/staff', verifyToken, authorizeRole([2]), staffCtrl.addPromotion);
router.put('/staff/:promotionId', verifyToken, authorizeRole([2]), staffCtrl.editPromotion);
router.delete('/staff/:promotionId', verifyToken, authorizeRole([2]), staffCtrl.removePromotion);

// ── Customer: danh sách tất cả voucher còn hiệu lực (PUBLIC) ─────────────────
router.get('/', customerCtrl.getAvailableVouchers);

// ── Customer: validate & preview voucher trước checkout ──────────────────────
router.post('/apply', verifyToken, customerCtrl.applyVoucher);

// ── Customer: lưu / xoá voucher đã thu thập ─────────────────────────────────
router.get('/my', verifyToken, customerCtrl.getMySavedVouchers);
router.post('/my/:promotionId', verifyToken, customerCtrl.saveVoucher);
router.delete('/my/:promotionId', verifyToken, customerCtrl.removeSavedVoucher);

module.exports = router;
