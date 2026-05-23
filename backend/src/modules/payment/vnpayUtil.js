/**
 * vnpayUtil.js
 * Các hàm tiện ích cho VNPay: tạo chữ ký HMAC-SHA512, sắp xếp params, format ngày giờ.
 * Cài đặt theo đúng chuẩn mã nguồn chính thức của VNPay.
 */

const crypto = require('crypto');
const qs = require('qs');

/**
 * Sắp xếp object theo key và encode cả key lẫn value (theo chuẩn VNPay chính thức)
 */
function sortObject(obj) {
    const sorted = {};
    const encodedKeys = Object.keys(obj)
        .map(k => encodeURIComponent(k))
        .sort();

    for (const encodedKey of encodedKeys) {
        const origKey = decodeURIComponent(encodedKey);
        sorted[encodedKey] = encodeURIComponent(obj[origKey]).replace(/%20/g, '+');
    }
    return sorted;
}

/**
 * Tạo chữ ký HMAC-SHA512 theo chuẩn VNPay chính thức
 * @param {Object} params - Object chứa các tham số (raw, chưa encode)
 * @param {string} secretKey - Secret key từ VNPay merchant
 * @returns {string} - Chuỗi chữ ký hex
 */
function createSignature(params, secretKey) {
    const sorted = sortObject(params);
    const signData = qs.stringify(sorted, { encode: false });

    console.log('[VNPAY] signData:', signData);

    const hmac = crypto.createHmac('sha512', secretKey);
    const hash = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
    console.log('[VNPAY] hash    :', hash);
    return hash;
}

/**
 * Xác minh chữ ký từ VNPay IPN/Return
 * @param {Object} params - Toàn bộ query params từ VNPay callback (đã decode bởi Express)
 * @param {string} secretKey
 * @returns {boolean}
 */
function verifySignature(params, secretKey) {
    const vnpSecureHash = params['vnp_SecureHash'];

    const cleanParams = { ...params };
    delete cleanParams['vnp_SecureHash'];
    delete cleanParams['vnp_SecureHashType'];

    const expectedHash = createSignature(cleanParams, secretKey);

    console.log('[VNPAY] Expected :', expectedHash);
    console.log('[VNPAY] Received :', vnpSecureHash);
    console.log('[VNPAY] Match?   :', vnpSecureHash?.toLowerCase() === expectedHash?.toLowerCase());

    return vnpSecureHash?.toLowerCase() === expectedHash?.toLowerCase();
}

/**
 * Format date thành chuỗi YYYYMMDDHHmmss theo múi giờ UTC+7
 */
function formatDate(date) {
    const pad = (n) => String(n).padStart(2, '0');
    const d = new Date(date.getTime() + 7 * 60 * 60 * 1000);
    return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}`;
}

/**
 * Tạo mã giao dịch ngẫu nhiên (txnRef)
 */
function createTxnRef(orderId) {
    const ts = Date.now().toString().slice(-6);
    return `${orderId}_${ts}`;
}

/**
 * Map mã lỗi VNPay sang message tiếng Việt
 */
function getResponseMessage(responseCode) {
    const messages = {
        '00': 'Giao dịch thành công',
        '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường)',
        '09': 'Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng',
        '10': 'Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
        '11': 'Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch',
        '12': 'Thẻ/Tài khoản của khách hàng bị khóa',
        '13': 'Quý khách nhập sai mật khẩu xác thực giao dịch (OTP). Xin quý khách vui lòng thực hiện lại giao dịch',
        '24': 'Khách hàng hủy giao dịch',
        '51': 'Tài khoản của quý khách không đủ số dư để thực hiện giao dịch',
        '65': 'Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày',
        '75': 'Ngân hàng thanh toán đang bảo trì',
        '79': 'KH nhập sai mật khẩu thanh toán quá số lần quy định',
        '99': 'Các lỗi khác',
    };
    return messages[responseCode] || 'Lỗi không xác định';
}

module.exports = {
    createSignature,
    verifySignature,
    formatDate,
    createTxnRef,
    getResponseMessage,
    sortObject,
};
