/**
 * dineInRoutes.js
 * API phục vụ chức năng "Gọi món tại bàn bằng QR".
 *
 * Public (không cần token):
 *   GET /api/dine-in/menu/:canteenId        — Lấy thực đơn của quán (dùng khi quét QR)
 *
 * Customer (role 1):
 *   POST /api/dine-in/checkout              — Đặt món tại bàn (không cần tòa/phòng)
 *
 * Staff (role 2):
 *   GET  /api/dine-in/staff/table-orders    — Lấy danh sách đơn tại bàn của quán
 *   GET  /api/dine-in/staff/qr-info         — Lấy thông tin tạo QR (maGianHang, tenGianHang, soBan)
 */

const express = require('express');
const router = express.Router();
const DineInController = require('../controllers/dineInController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// ── Public ──────────────────────────────────────────────────────────────────
router.get('/menu/:canteenId', DineInController.getMenuPublic);

// Giao diện Web HTML để test trên Chrome máy tính
router.get('/web-view/:canteenId', (req, res) => {
    const path = require('path');
    res.sendFile(path.resolve(__dirname, '../../public/dine_in_menu.html'));
});

// API Checkout cho khách vãng lai gọi qua trình duyệt web (không cần token)
router.post('/checkout-web', DineInController.checkoutDineInWeb);

// API Lấy trạng thái thanh toán của một đơn hàng (không cần token)
router.get('/payment-status/:maDonHang', DineInController.getPaymentStatusPublic);

// API Lấy tổng hợp hóa đơn của một bàn (không cần token)
router.get('/table-bill/:maGianHang/:soBanAn', DineInController.getTableBillPublic);

// ── Customer (role 1) ────────────────────────────────────────────────────────
router.post('/checkout', verifyToken, authorizeRole([1]), DineInController.checkoutDineIn);

// ── Staff (role 2) ───────────────────────────────────────────────────────────
router.get('/staff/table-orders',  verifyToken, authorizeRole([2]), DineInController.getTableOrders);
router.get('/staff/table-orders/:id', verifyToken, authorizeRole([2]), DineInController.getTableOrderDetail);
router.post('/staff/table-orders/:id/add-item', verifyToken, authorizeRole([2]), DineInController.addItemToTableOrder);
router.delete('/staff/table-orders/:id/items/:chiTietId', verifyToken, authorizeRole([2]), DineInController.removeItemFromTableOrder);
router.get('/staff/qr-info',       verifyToken, authorizeRole([2]), DineInController.getQrInfo);
router.get('/staff/menu',          verifyToken, authorizeRole([2]), DineInController.getStaffMenuForDineIn);
router.put('/staff/tables',        verifyToken, authorizeRole([2]), DineInController.updateTables);
router.put('/staff/table-orders/:id/start',  verifyToken, authorizeRole([2]), DineInController.startTableOrder);
router.put('/staff/table-orders/:id/done',   verifyToken, authorizeRole([2]), DineInController.doneTableOrder);

module.exports = router;
