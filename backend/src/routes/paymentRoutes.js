const express = require('express');
const router = express.Router();
const PaymentController = require('../modules/payment/paymentController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// Public — SePay gọi server-to-server, không cần token
router.post('/sepay-webhook', PaymentController.sepayWebhook);

// Protected — chỉ customer
router.use(verifyToken);
router.post('/create',                authorizeRole([1]), PaymentController.createPayment);
router.post('/manual-confirm',        authorizeRole([1]), PaymentController.manualConfirm);
router.post('/refund',                authorizeRole([1]), PaymentController.refundPayment);
router.get('/status/:maDonHang',      authorizeRole([1]), PaymentController.getStatus);

module.exports = router;
