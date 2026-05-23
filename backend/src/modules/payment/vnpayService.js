/**
 * vnpayService.js
 * Logic nghiệp vụ VNPay: tạo URL thanh toán, xác minh IPN.
 * Build URL theo đúng chuẩn chính thức VNPay (sortObject + qs.stringify).
 */

const qs = require('qs');
const { createSignature, verifySignature, formatDate, createTxnRef, getResponseMessage, sortObject } = require('./vnpayUtil');

// ── Cấu hình VNPay (nên để vào .env) ───────────────────────────────────────
const VNPAY_CONFIG = {
    tmnCode:   process.env.VNPAY_TMN_CODE   || 'DEMOTMN',
    secretKey: process.env.VNPAY_HASH_KEY   || 'DEMOSECRETKEY',
    vnpUrl:    process.env.VNPAY_URL        || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNPAY_RETURN_URL || 'http://10.0.2.2:3001/api/payment/vnpay-return',
    ipnUrl:    process.env.VNPAY_IPN_URL    || 'http://10.0.2.2:3001/api/payment/vnpay-ipn',
    locale:    'vn',
    currCode:  'VND',
    version:   '2.1.0',
    command:   'pay',
    orderType: 'other',
};

/**
 * Tạo URL thanh toán VNPay
 */
function createPaymentUrl({ orderId, amount, orderInfo, clientIp, bankCode = '' }) {
    const txnRef    = createTxnRef(orderId);
    const createDate = formatDate(new Date());

    const vnpParams = {
        vnp_Version:    VNPAY_CONFIG.version,
        vnp_Command:    VNPAY_CONFIG.command,
        vnp_TmnCode:    VNPAY_CONFIG.tmnCode,
        vnp_Locale:     VNPAY_CONFIG.locale,
        vnp_CurrCode:   VNPAY_CONFIG.currCode,
        vnp_TxnRef:     txnRef,
        vnp_OrderInfo:  orderInfo || `Thanh toan don hang #${orderId}`,
        vnp_OrderType:  VNPAY_CONFIG.orderType,
        vnp_Amount:     amount * 100,   // VNPay tính theo đơn vị nhỏ nhất (x100)
        vnp_ReturnUrl:  VNPAY_CONFIG.returnUrl,
        vnp_IpAddr:     clientIp || '127.0.0.1',
        vnp_CreateDate: createDate,
    };

    if (bankCode) {
        vnpParams.vnp_BankCode = bankCode;
    }

    console.log('[VNPAY] Config returnUrl:', VNPAY_CONFIG.returnUrl);

    // Ký chữ ký trên raw params (chưa encode)
    const secureHash = createSignature(vnpParams, VNPAY_CONFIG.secretKey);

    // Build URL: sort + encode + append hash ở cuối (theo chuẩn VNPay)
    const sortedParams = sortObject(vnpParams);
    sortedParams['vnp_SecureHash'] = secureHash;
    const payUrl = `${VNPAY_CONFIG.vnpUrl}?${qs.stringify(sortedParams, { encode: false })}`;

    console.log('[VNPAY] payUrl:', payUrl);

    return { payUrl, txnRef };
}

/**
 * Xác minh callback từ VNPay (Return URL hoặc IPN)
 */
function verifyCallback(query) {
    const isValid = verifySignature(query, VNPAY_CONFIG.secretKey);
    const responseCode = query['vnp_ResponseCode'] || '';
    const txnRef = query['vnp_TxnRef'] || '';
    const orderId = txnRef.split('_')[0];

    return {
        isValid,
        responseCode,
        txnRef,
        orderId,
        amount: parseInt(query['vnp_Amount'] || '0') / 100,
        message: getResponseMessage(responseCode),
        success: isValid && responseCode === '00',
    };
}

module.exports = { createPaymentUrl, verifyCallback, VNPAY_CONFIG };
