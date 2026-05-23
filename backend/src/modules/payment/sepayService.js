/**
 * sepayService.js
 * Logic tích hợp SePay:
 *  - Tạo mã nội dung chuyển khoản (code)
 *  - Tạo URL QR VietQR
 *  - Xác minh webhook từ SePay
 */

const crypto = require('crypto');

// ── Cấu hình SePay (từ .env) ─────────────────────────────────────────────────
const SEPAY_CONFIG = {
    bankCode:      process.env.SEPAY_BANK_CODE    || 'MB',          // Mã ngân hàng (MB, VCB, TCB,...)
    accountNumber: process.env.SEPAY_ACCOUNT_NO   || '0000000000',  // Số tài khoản
    accountName:   process.env.SEPAY_ACCOUNT_NAME || 'SHIP FOOD',   // Tên tài khoản
    apiKey:        process.env.SEPAY_API_KEY       || '',            // API Key từ dashboard SePay (dùng để xác thực webhook)
    prefix:        process.env.SEPAY_CODE_PREFIX   || 'SF',         // Prefix mã giao dịch
};

/**
 * Tạo mã nội dung chuyển khoản (unique per order)
 * Format: SF{maDonHang} — ngắn gọn để user nhập nếu cần
 */
function createPaymentCode(maDonHang) {
    return `${SEPAY_CONFIG.prefix}${maDonHang}`;
}

/**
 * Tạo URL QR VietQR
 * Sử dụng API ảnh công khai của VietQR: https://img.vietqr.io
 */
function createQrUrl({ maDonHang, amount }) {
    const code = createPaymentCode(maDonHang);
    const addInfo = encodeURIComponent(code);
    const accountName = encodeURIComponent(SEPAY_CONFIG.accountName);
    return `https://img.vietqr.io/image/${SEPAY_CONFIG.bankCode}-${SEPAY_CONFIG.accountNumber}-compact2.jpg?amount=${amount}&addInfo=${addInfo}&accountName=${accountName}`;
}

/**
 * Xác thực request webhook từ SePay
 * SePay gửi header: Authorization: Apikey <YOUR_API_KEY>
 */
function verifyWebhook(req) {
    if (!SEPAY_CONFIG.apiKey) return true; // Bỏ qua nếu chưa cấu hình key
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.replace(/^Apikey\s+/i, '').trim();
    return token === SEPAY_CONFIG.apiKey;
}

/**
 * Parse payload webhook SePay và trích xuất mã đơn hàng
 * Payload mẫu: { id, gateway, transactionDate, accountNumber, code, content, transferAmount, referenceCode }
 */
function parseWebhookPayload(body) {
    const content = (body.content || '').toString().trim();
    const transferAmount = Number(body.transferAmount) || 0;
    const transactionId = body.id?.toString() || '';

    // Tìm mã đơn trong nội dung chuyển khoản (ví dụ: "SF12 chuyen tien")
    const prefix = SEPAY_CONFIG.prefix;
    const regex = new RegExp(`${prefix}(\\d+)`, 'i');
    const match = content.match(regex);
    const maDonHang = match ? parseInt(match[1]) : null;
    const code = maDonHang ? createPaymentCode(maDonHang) : null;

    return { content, transferAmount, transactionId, maDonHang, code };
}

module.exports = { createPaymentCode, createQrUrl, verifyWebhook, parseWebhookPayload, SEPAY_CONFIG };
