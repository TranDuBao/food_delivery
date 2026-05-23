const cron = require('node-cron');
const OrderModel = require('../models/orderModel');

const startCronJobs = () => {
    console.log('[CronJob] Initialized. Will check for order groupings every minute.');

    // Chạy mỗi phút (* * * * *)
    cron.schedule('* * * * *', async () => {
        console.log(`[CronJob] Running at ${new Date().toISOString()}...`);
        try {
            // Lấy ra các nhóm (Tòa nhà) có khu vực đang có đơn chờ trên 5 phút
            const groups = await OrderModel.getPendingGroups();

            for (const group of groups) {
                const { maToaNha } = group;

                // Lấy tất cả các maDonHang thuộc đang ở mode chờ ghép đơn ở khu vực này 
                // Cứ có ít nhất 1 thằng đợt này nổ (>= 5p) là đem cả rổ những thằng khác đang hóng đi xét luôn
                const pendingOrders = await OrderModel.getPendingOrdersByGroup(maToaNha);

                if (pendingOrders.length === 0) continue;

                // Quy định gom đơn được thống nhất: Nếu có TỪ 2 ĐƠN trở lên thì mới gom
                if (pendingOrders.length >= 2) {
                    console.log(`[CronJob] Grouping ${pendingOrders.length} orders for ${maToaNha}`);
                    await OrderModel.groupOrdersToDelivery(maToaNha, pendingOrders);
                } else {
                    // Nếu sau 5p mà không tích đủ ít nhất 2 đơn -> Sẽ hủy đơn
                    console.log(`[CronJob] Canceling ${pendingOrders.length} order(s) for ${maToaNha} due to insufficient match.`);
                    await OrderModel.cancelOrders(pendingOrders);
                }
            }
        } catch (error) {
            console.error('[CronJob Error] Error while processing grouped orders:', error);
        }
    });
};

module.exports = { startCronJobs };
