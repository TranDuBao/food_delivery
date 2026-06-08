/**
 * paymentController.js
 * Controller thanh toán bằng SePay (QR chuyển khoản ngân hàng):
 *   POST /api/payment/create          → Tạo mã thanh toán + QR URL
 *   POST /api/payment/sepay-webhook   → Nhận webhook từ SePay (server-to-server)
 *   GET  /api/payment/status/:maDonHang → Kiểm tra trạng thái thanh toán
 *   POST /api/payment/refund          → Ghi nhận yêu cầu hoàn tiền
 */

const { createPaymentCode, createQrUrl, verifyWebhook, parseWebhookPayload, SEPAY_CONFIG } = require('./sepayService');
const db = require('../../config/db');
const CartModel = require('../../models/cartModel');

const PaymentController = {

    /**
     * POST /api/payment/create
     * Body: { maDonHang, tongTien }
     * Trả về: { success, paymentCode, qrUrl, accountNumber, accountName, bankCode, amount }
     */
    createPayment: async (req, res, next) => {
        try {
            const { maDonHang, tongTien } = req.body;

            if (!maDonHang || !tongTien) {
                return res.status(400).json({ success: false, message: 'Thiếu maDonHang hoặc tongTien' });
            }

            // Kiểm tra đơn hàng thuộc về user
            const [order] = await db.query(
                'SELECT maDonHang, tongTien, trangThaiDonHang FROM donhang WHERE maDonHang = ? AND maTaiKhoan = ?',
                [maDonHang, req.user.maTaiKhoan]
            );

            if (!order) {
                return res.status(404).json({ success: false, message: 'Đơn hàng không tồn tại' });
            }

            const amount = Math.round(tongTien);
            const paymentCode = createPaymentCode(maDonHang);
            const qrUrl = createQrUrl({ maDonHang, amount });

            // Lưu vào DB để đối chiếu webhook
            await db.query(
                `INSERT INTO thanhtoan (maDonHang, txnRef, soTien, trangThai, thoiGianTao)
                 VALUES (?, ?, ?, 'pending', NOW())
                 ON DUPLICATE KEY UPDATE txnRef = VALUES(txnRef), soTien = VALUES(soTien), thoiGianTao = NOW()`,
                [maDonHang, paymentCode, amount]
            );

            return res.json({
                success: true,
                paymentCode,
                qrUrl,
                accountNumber: SEPAY_CONFIG.accountNumber,
                accountName:   SEPAY_CONFIG.accountName,
                bankCode:      SEPAY_CONFIG.bankCode,
                amount,
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * POST /api/payment/sepay-webhook
     * SePay gọi server-to-server khi phát hiện giao dịch.
     * Phải trả về { success: true } trong 30 giây.
     */
    sepayWebhook: async (req, res) => {
        try {
            // Xác thực request
            if (!verifyWebhook(req)) {
                console.warn('[SePay Webhook] Unauthorized request');
                return res.status(401).json({ success: false, message: 'Unauthorized' });
            }

            const payload = parseWebhookPayload(req.body);
            console.log('[SePay Webhook] Received:', payload);

            if (!payload.maDonHang) {
                // Giao dịch không khớp đơn hàng nào → bỏ qua nhưng vẫn trả 200
                return res.json({ success: true, message: 'No matching order' });
            }

            // Idempotency: kiểm tra đã xử lý chưa
            const [existing] = await db.query(
                'SELECT trangThai FROM thanhtoan WHERE maDonHang = ? AND txnRef = ?',
                [payload.maDonHang, payload.code]
            );

            if (existing && existing.trangThai === 'success') {
                return res.json({ success: true, message: 'Already processed' });
            }

            // Cập nhật trạng thái thanh toán
            await db.query(
                `UPDATE donhang SET trangThaiThanhToan = 'paid', phuongThucThanhToan = 'SEPAY'
                 WHERE maDonHang = ?`,
                [payload.maDonHang]
            );

            await db.query(
                `UPDATE thanhtoan SET trangThai = 'success', maGiaoDich = ?, thoiGianHoanTat = NOW()
                 WHERE maDonHang = ? AND txnRef = ?`,
                [payload.transactionId, payload.maDonHang, payload.code]
            );

            // Xóa giỏ hàng
            const [orderInfo] = await db.query(
                'SELECT maTaiKhoan FROM donhang WHERE maDonHang = ?',
                [payload.maDonHang]
            );
            if (orderInfo) {
                await CartModel.clearCart(orderInfo.maTaiKhoan);
                console.log(`[SePay] Cleared cart for user ${orderInfo.maTaiKhoan}, order ${payload.maDonHang}`);
            }

            return res.json({ success: true });
        } catch (error) {
            console.error('[SePay Webhook Error]', error);
            // Vẫn trả 200 để SePay không retry liên tục
            return res.json({ success: false, message: 'Internal error' });
        }
    },

    /**
     * GET /api/payment/status/:maDonHang
     * Flutter polling để biết đơn đã được thanh toán chưa.
     * Ưu tiên: DB local → SePay API (fallback khi webhook không về được)
     */
    getStatus: async (req, res, next) => {
        try {
            const { maDonHang } = req.params;
            const [payment] = await db.query(
                `SELECT tt.trangThai, tt.txnRef, tt.soTien, tt.thoiGianHoanTat, tt.maGiaoDich,
                        d.trangThaiThanhToan
                 FROM thanhtoan tt
                 JOIN donhang d ON d.maDonHang = tt.maDonHang
                 WHERE tt.maDonHang = ? AND d.maTaiKhoan = ?
                 ORDER BY tt.thoiGianTao DESC LIMIT 1`,
                [maDonHang, req.user.maTaiKhoan]
            );

            if (!payment) {
                return res.json({ success: true, data: { trangThai: 'not_found' } });
            }

            // Nếu đã success trong DB → trả về luôn
            if (payment.trangThai === 'success' || payment.trangThaiThanhToan === 'paid') {
                return res.json({ success: true, data: payment });
            }

            // ── Fallback: Query SePay API trực tiếp ──────────────────────────
            // Hữu ích khi webhook không về được (localhost, dev env)
            const SEPAY_API_KEY = process.env.SEPAY_API_KEY || '';
            if (SEPAY_API_KEY && payment.txnRef) {
                try {
                    const https = require('https');
                    const sepayUrl = `https://my.sepay.vn/userapi/transactions/list?transaction_content=${payment.txnRef}&limit=5`;
                    const sepayData = await new Promise((resolve, reject) => {
                        const reqHttp = https.get(sepayUrl, {
                            headers: { 'Authorization': `Bearer ${SEPAY_API_KEY}` }
                        }, (resp) => {
                            let data = '';
                            resp.on('data', chunk => data += chunk);
                            resp.on('end', () => {
                                try { resolve(JSON.parse(data)); } catch { resolve({}); }
                            });
                        });
                        reqHttp.on('error', reject);
                        reqHttp.setTimeout(5000, () => { reqHttp.destroy(); reject(new Error('timeout')); });
                    });

                    const transactions = sepayData?.transactions || sepayData?.data || [];
                    const matched = transactions.find(t => {
                        const content = (t.transaction_content || t.content || '').toUpperCase();
                        return content.includes(payment.txnRef.toUpperCase());
                    });

                    if (matched) {
                        // Tự cập nhật DB
                        await db.query(
                            `UPDATE donhang SET trangThaiThanhToan = 'paid', phuongThucThanhToan = 'SEPAY' WHERE maDonHang = ?`,
                            [maDonHang]
                        );
                        await db.query(
                            `UPDATE thanhtoan SET trangThai = 'success', maGiaoDich = ?, thoiGianHoanTat = NOW() WHERE maDonHang = ?`,
                            [matched.id || matched.reference_number || '', maDonHang]
                        );
                        return res.json({ success: true, data: { trangThai: 'success', trangThaiThanhToan: 'paid' } });
                    }
                } catch (sepayErr) {
                    console.warn('[getStatus] SePay API fallback error:', sepayErr.message);
                }
            }

            return res.json({ success: true, data: payment });
        } catch (error) {
            next(error);
        }
    },


    /**
     * POST /api/payment/refund
     * Body: { maDonHang }
     * Ghi nhận yêu cầu hoàn tiền (thủ công, admin xử lý sau).
     */
    refundPayment: async (req, res, next) => {
        try {
            const { maDonHang } = req.body;
            const maTaiKhoan = req.user.maTaiKhoan;

            const [order] = await db.query(
                `SELECT * FROM donhang 
                 WHERE maDonHang = ? AND maTaiKhoan = ? 
                   AND trangThaiThanhToan = 'paid' 
                   AND trangThaiDonHang IN ('choGhepDon', 'choXacNhan')`,
                [maDonHang, maTaiKhoan]
            );

            if (!order) {
                return res.status(400).json({
                    success: false,
                    message: 'Đơn hàng không đủ điều kiện hoàn tiền (phải là đơn đã thanh toán và chưa được chuẩn bị).'
                });
            }

            await db.query(
                "UPDATE donhang SET trangThaiDonHang = 'daHuy', trangThaiThanhToan = 'refunded' WHERE maDonHang = ?",
                [maDonHang]
            );

            await db.query(
                "UPDATE thanhtoan SET trangThai = 'refunded', thoiGianHoanTat = NOW() WHERE maDonHang = ?",
                [maDonHang]
            );

            return res.json({
                success: true,
                message: 'Yêu cầu hoàn tiền đã được ghi nhận. Tiền sẽ được hoàn lại vào tài khoản của bạn trong 1-3 ngày làm việc.'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * POST /api/payment/manual-confirm  [DEV/DEMO]
     * Body: { maDonHang }
     * Đánh dấu đơn đã thanh toán thủ công (dùng khi webhook không về được localhost).
     */
    manualConfirm: async (req, res, next) => {
        try {
            const { maDonHang } = req.body;
            const maTaiKhoan = req.user.maTaiKhoan;

            const [order] = await db.query(
                `SELECT maDonHang FROM donhang WHERE maDonHang = ? AND maTaiKhoan = ?`,
                [maDonHang, maTaiKhoan]
            );

            if (!order) {
                return res.status(404).json({ success: false, message: 'Đơn hàng không tồn tại' });
            }

            await db.query(
                `UPDATE donhang SET trangThaiThanhToan = 'paid', phuongThucThanhToan = 'SEPAY' WHERE maDonHang = ?`,
                [maDonHang]
            );
            await db.query(
                `UPDATE thanhtoan SET trangThai = 'success', thoiGianHoanTat = NOW() WHERE maDonHang = ?`,
                [maDonHang]
            );

            console.log(`[ManualConfirm] Order ${maDonHang} marked as paid by user ${maTaiKhoan}`);
            return res.json({ success: true, data: { trangThai: 'success', trangThaiThanhToan: 'paid' } });
        } catch (error) {
            next(error);
        }
    },
};

module.exports = PaymentController;
