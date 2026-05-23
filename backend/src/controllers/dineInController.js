/**
 * dineInController.js
 * Xử lý luồng "Gọi món tại bàn bằng QR":
 *   GET  /api/dine-in/menu/:canteenId     — Lấy thực đơn quán (public)
 *   POST /api/dine-in/checkout            — Khách đặt món tại bàn
 *   GET  /api/dine-in/staff/table-orders  — Staff xem đơn tại bàn
 *   GET  /api/dine-in/staff/qr-info       — Staff lấy thông tin QR của quán mình
 *   PUT  /api/dine-in/staff/table-orders/:id/start — Bắt đầu chuẩn bị
 *   PUT  /api/dine-in/staff/table-orders/:id/done  — Hoàn thành
 */

const db = require('../config/db');
const CartModel = require('../models/cartModel');
const { createPaymentCode, createQrUrl, SEPAY_CONFIG } = require('../modules/payment/sepayService');

const DineInController = {

    /**
     * GET /api/dine-in/menu/:canteenId
     * Public – Trả về thông tin quán + tất cả món đang hoạt động.
     * Đây là URL mà QR Code sẽ chứa khi quét bằng trình duyệt.
     * Flutter deep link: shipfood://canteen/{id}
     */
    getMenuPublic: async (req, res, next) => {
        try {
            const { canteenId } = req.params;

            // Thông tin quán (kèm soBan)
            const [canteen] = await db.query(
                `SELECT maGianHang, tenGianHang, moTa, banner, soDienThoai, gioMoCua, trangThai, soBan
                 FROM gianhang WHERE maGianHang = ?`,
                [canteenId]
            );

            if (!canteen) {
                return res.status(404).json({ success: false, message: 'Quán không tồn tại.' });
            }

            // Helper để map URL hình ảnh
            const host = req.get('host');
            const protocol = req.protocol;
            const formatImageUrl = (url) => {
                if (!url) return '';
                // Nếu bắt đầu bằng http://10.0.2.2:3001 mà client truy cập bằng localhost
                let formatted = url;
                if (formatted.includes('10.0.2.2:3001') && !host.includes('10.0.2.2')) {
                    formatted = formatted.replace('10.0.2.2:3001', host);
                }
                if (!formatted.startsWith('http')) {
                    // Nếu là đường dẫn tương đối /uploads/... hoặc /img/...
                    formatted = `${protocol}://${host}${formatted.startsWith('/') ? '' : '/'}${formatted}`;
                }
                return formatted;
            };

            canteen.banner = formatImageUrl(canteen.banner);

            // Danh sách món ăn theo danh mục
            const dishes = await db.query(
                `SELECT m.maMonAn, m.tenMonAn, m.moTa, m.giaTien, m.hinhAnh,
                        m.trangThai, m.daXoa,
                        COALESCE(m.diemDanhGia, 0) AS diemDanhGia,
                        COALESCE(m.luotDanhGia, 0) AS luotDanhGia,
                        COALESCE(m.soLuongDaBan, 0) AS soLuongDaBan,
                        dm.tenDanhMuc
                 FROM monan m
                 LEFT JOIN danhMuc dm ON m.maDanhMuc = dm.maDanhMuc
                 WHERE m.maGianHang = ? AND m.daXoa = 0 AND m.trangThai = 1
                 ORDER BY dm.tenDanhMuc, m.tenMonAn`,
                [canteenId]
            );

            dishes.forEach(dish => {
                dish.hinhAnh = formatImageUrl(dish.hinhAnh);
            });

            return res.json({
                success: true,
                data: { canteen, dishes }
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * GET /api/dine-in/staff/qr-info
     * Staff – Trả về thông tin để tạo QR Code quét vào menu quán.
     */
    getQrInfo: async (req, res, next) => {
        try {
            const [canteen] = await db.query(
                'SELECT maGianHang, tenGianHang, soBan FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );

            if (!canteen) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }

            const deepLink = `shipfood://canteen/${canteen.maGianHang}`;
            let host = req.get('host'); // Lấy IP, port hoặc ngrok domain động
            if (host.includes('10.0.2.2')) {
                host = host.replace('10.0.2.2', 'localhost');
            }
            const webLink = `${req.protocol}://${host}/api/dine-in/web-view/${canteen.maGianHang}`;

            return res.json({
                success: true,
                data: {
                    maGianHang: canteen.maGianHang,
                    tenGianHang: canteen.tenGianHang,
                    soBan: canteen.soBan || 10,
                    deepLink,
                    webLink,
                }
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * POST /api/dine-in/checkout
     * Customer – Đặt món tại quán (không cần tòa/phòng, chỉ cần maGianHang + items).
     * Body: { maGianHang, items: [{maMonAn, soLuong, giaTien}], tongTien }
     */
    checkoutDineIn: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { maGianHang, items, tongTien, soBanAn } = req.body;

            if (!maGianHang) {
                return res.status(400).json({ success: false, message: 'Thiếu maGianHang.' });
            }
            if (!items || items.length === 0) {
                return res.status(400).json({ success: false, message: 'Giỏ hàng trống!' });
            }

            // Tạo đơn hàng dine-in (maToaNha = null, maPhong = null, có soBanAn)
            const orderResult = await db.query(
                `INSERT INTO donhang 
                    (maTaiKhoan, maToaNha, maPhong, tongTien, trangThaiDonHang, 
                     trangThaiThanhToan, phuongThucThanhToan, loaiDonHang, thoiGianDat, soBanAn)
                 VALUES (?, NULL, NULL, ?, 'choXacNhan', 'pending', 'SEPAY', 'dineIn', NOW(), ?)`,
                [maTaiKhoan, Math.round(tongTien), soBanAn || null]
            );

            const maDonHang = orderResult.insertId;

            // Thêm chi tiết đơn hàng
            for (const item of items) {
                await db.query(
                    `INSERT INTO chitietdonhang (maDonHang, maMonAn, soLuong, giaTien, trangThaiMon)
                     VALUES (?, ?, ?, ?, 'pending')`,
                    [maDonHang, item.maMonAn, item.soLuong, item.giaTien]
                );
            }

            // Xóa giỏ hàng
            await CartModel.clearCart(maTaiKhoan);

            return res.status(201).json({
                success: true,
                message: 'Đặt món thành công! Quán đang nhận đơn của bạn.',
                data: { maDonHang, maGianHang }
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * POST /api/dine-in/checkout-web
     * Khách vãng lai gọi qua Chrome (không cần đăng nhập)
     */
    checkoutDineInWeb: async (req, res, next) => {
        try {
            const { maGianHang, items, tongTien, tenKhach, soDienThoai, soBanAn } = req.body;

            if (!maGianHang) {
                return res.status(400).json({ success: false, message: 'Thiếu maGianHang.' });
            }
            if (!items || items.length === 0) {
                return res.status(400).json({ success: false, message: 'Giỏ hàng trống!' });
            }

            const [defaultUser] = await db.query(`SELECT maTaiKhoan FROM taikhoan LIMIT 1`);
            const maTaiKhoan = defaultUser ? defaultUser.maTaiKhoan : 1;

            // Lưu tên + SĐT theo format "TenKhach||SoDienThoai" để tra cứu sau
            const tenLuu = soDienThoai
                ? `${tenKhach || 'Khách'}||${soDienThoai}`
                : (tenKhach || 'Khách ăn tại bàn');

            const orderResult = await db.query(
                `INSERT INTO donhang 
                    (maTaiKhoan, maToaNha, maPhong, tongTien, trangThaiDonHang, 
                     trangThaiThanhToan, phuongThucThanhToan, loaiDonHang, thoiGianDat, soBanAn, tenKhachDineIn)
                 VALUES (?, NULL, NULL, ?, 'choXacNhan', 'pending', 'COD', 'dineIn', NOW(), ?, ?)`,
                [maTaiKhoan, Math.round(tongTien), soBanAn || null, tenLuu]
            );

            const maDonHang = orderResult.insertId;

            for (const item of items) {
                await db.query(
                    `INSERT INTO chitietdonhang (maDonHang, maMonAn, soLuong, giaTien, trangThaiMon)
                     VALUES (?, ?, ?, ?, 'pending')`,
                    [maDonHang, item.maMonAn, item.soLuong, item.giaTien]
                );
            }

            return res.status(201).json({
                success: true,
                message: 'Đặt món thành công!',
                data: { maDonHang, maGianHang }
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * GET /api/dine-in/staff/table-orders/:id
     * Staff – Lấy chi tiết một đơn tại bàn kèm danh sách món.
     */
    getTableOrderDetail: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            const [canteen] = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!canteen) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });

            const [order] = await db.query(
                `SELECT d.maDonHang, d.tongTien, d.trangThaiDonHang, d.trangThaiThanhToan,
                        d.phuongThucThanhToan, d.thoiGianDat, d.soBanAn,
                        COALESCE(d.tenKhachDineIn, tk.hoTen) AS tenKhach
                 FROM donhang d
                 LEFT JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
                 WHERE d.maDonHang = ? AND d.loaiDonHang = 'dineIn'`,
                [maDonHang]
            );
            if (!order) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });

            const items = await db.query(
                `SELECT ct.maChiTietDonHang, ct.soLuong, ct.giaTien, m.tenMonAn, m.maMonAn, m.hinhAnh
                 FROM chitietdonhang ct
                 JOIN monan m ON ct.maMonAn = m.maMonAn
                 WHERE ct.maDonHang = ? AND m.maGianHang = ?`,
                [maDonHang, canteen.maGianHang]
            );

            const host = req.get('host'), protocol = req.protocol;
            items.forEach(item => {
                if (item.hinhAnh && !item.hinhAnh.startsWith('http')) {
                    item.hinhAnh = `${protocol}://${host}${item.hinhAnh.startsWith('/') ? '' : '/'}${item.hinhAnh}`;
                }
            });

            return res.json({ success: true, data: { ...order, items } });
        } catch (error) { next(error); }
    },

    /**
     * POST /api/dine-in/staff/table-orders/:id/add-item
     * Staff – Thêm món vào đơn tại bàn. Nếu món đã có → tăng số lượng.
     */
    addItemToTableOrder: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            const { maMonAn, soLuong = 1 } = req.body;
            const [canteen] = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!canteen) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });

            const [dish] = await db.query('SELECT maMonAn, giaTien FROM monan WHERE maMonAn = ? AND maGianHang = ?', [maMonAn, canteen.maGianHang]);
            if (!dish) return res.status(404).json({ success: false, message: 'Món không thuộc quán này.' });

            const [existing] = await db.query('SELECT maChiTietDonHang, soLuong FROM chitietdonhang WHERE maDonHang = ? AND maMonAn = ?', [maDonHang, maMonAn]);
            if (existing) {
                await db.query('UPDATE chitietdonhang SET soLuong = soLuong + ? WHERE maChiTietDonHang = ?', [soLuong, existing.maChiTietDonHang]);
            } else {
                await db.query(`INSERT INTO chitietdonhang (maDonHang, maMonAn, soLuong, giaTien, trangThaiMon) VALUES (?, ?, ?, ?, 'pending')`, [maDonHang, maMonAn, soLuong, dish.giaTien]);
            }

            const [total] = await db.query('SELECT SUM(soLuong * giaTien) as t FROM chitietdonhang WHERE maDonHang = ?', [maDonHang]);
            await db.query('UPDATE donhang SET tongTien = ? WHERE maDonHang = ?', [Math.round(total?.t || 0), maDonHang]);

            return res.json({ success: true, message: 'Đã thêm món vào đơn.' });
        } catch (error) { next(error); }
    },

    /**
     * DELETE /api/dine-in/staff/table-orders/:id/items/:chiTietId
     * Staff – Xóa một món khỏi đơn tại bàn.
     */
    removeItemFromTableOrder: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            const chiTietId = Number(req.params.chiTietId);
            const [canteen] = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!canteen) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });

            await db.query(
                `DELETE ct FROM chitietdonhang ct JOIN monan m ON ct.maMonAn = m.maMonAn
                 WHERE ct.maChiTietDonHang = ? AND ct.maDonHang = ? AND m.maGianHang = ?`,
                [chiTietId, maDonHang, canteen.maGianHang]
            );

            const [total] = await db.query('SELECT SUM(soLuong * giaTien) as t FROM chitietdonhang WHERE maDonHang = ?', [maDonHang]);
            await db.query('UPDATE donhang SET tongTien = ? WHERE maDonHang = ?', [Math.round(total?.t || 0), maDonHang]);

            return res.json({ success: true, message: 'Đã xóa món.' });
        } catch (error) { next(error); }
    },

    /**
     * GET /api/dine-in/staff/menu
     * Staff – Lấy menu quán để thêm món vào đơn tại bàn.
     */
    getStaffMenuForDineIn: async (req, res, next) => {
        try {
            const [canteen] = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!canteen) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });

            const dishes = await db.query(
                `SELECT m.maMonAn, m.tenMonAn, m.giaTien, m.hinhAnh, COALESCE(dm.tenDanhMuc, 'Khác') as tenDanhMuc
                 FROM monan m LEFT JOIN danhMuc dm ON m.maDanhMuc = dm.maDanhMuc
                 WHERE m.maGianHang = ? AND m.trangThai = 1 AND m.daXoa = 0
                 ORDER BY dm.tenDanhMuc, m.tenMonAn`,
                [canteen.maGianHang]
            );

            const host = req.get('host'), protocol = req.protocol;
            dishes.forEach(d => {
                if (d.hinhAnh && !d.hinhAnh.startsWith('http')) {
                    d.hinhAnh = `${protocol}://${host}${d.hinhAnh.startsWith('/') ? '' : '/'}${d.hinhAnh}`;
                }
            });

            return res.json({ success: true, data: dishes });
        } catch (error) { next(error); }
    },

    /**
     * GET /api/dine-in/staff/table-orders
     * Staff – Lấy danh sách đơn dine-in của quán (loaiDonHang = 'dineIn').
     */
    getTableOrders: async (req, res, next) => {
        try {
            const [canteen] = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!canteen) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }

            const orders = await db.query(
                `SELECT d.maDonHang, d.tongTien, d.trangThaiDonHang, d.trangThaiThanhToan,
                        d.phuongThucThanhToan, d.thoiGianDat, d.loaiDonHang, d.soBanAn,
                        COALESCE(d.tenKhachDineIn, tk.hoTen) AS tenKhach, tk.soDienThoai,
                        GROUP_CONCAT(
                            CONCAT(m.tenMonAn, ' x', ct.soLuong) 
                            ORDER BY m.tenMonAn SEPARATOR ', '
                        ) AS danhSachMon
                 FROM donhang d
                 LEFT JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
                 JOIN chitietdonhang ct ON ct.maDonHang = d.maDonHang
                 JOIN monan m ON ct.maMonAn = m.maMonAn
                 WHERE m.maGianHang = ? 
                   AND d.loaiDonHang = 'dineIn'
                   AND d.trangThaiDonHang NOT IN ('daHuy')
                 GROUP BY d.maDonHang
                 ORDER BY d.thoiGianDat DESC
                 LIMIT 50`,
                [canteen.maGianHang]
            );

            return res.json({ success: true, data: orders });
        } catch (error) {
            next(error);
        }
    },

    /**
     * PUT /api/dine-in/staff/table-orders/:id/start
     * Staff – Bắt đầu chuẩn bị đơn tại bàn.
     */
    startTableOrder: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            await db.query(
                `UPDATE donhang SET trangThaiDonHang = 'dangChuanBi' 
                 WHERE maDonHang = ? AND trangThaiDonHang = 'choXacNhan'`,
                [maDonHang]
            );
            return res.json({ success: true, message: 'Đã bắt đầu chuẩn bị.' });
        } catch (error) {
            next(error);
        }
    },

    /**
     * PUT /api/dine-in/staff/table-orders/:id/done
     * Staff – Đánh dấu đơn tại bàn đã hoàn thành (đã bưng ra).
     */
    doneTableOrder: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            await db.query(
                `UPDATE donhang SET trangThaiDonHang = 'daGiao' 
                 WHERE maDonHang = ?`,
                [maDonHang]
            );
            await db.query(
                `UPDATE chitietdonhang SET trangThaiMon = 'delivered' 
                 WHERE maDonHang = ?`,
                [maDonHang]
            );
            return res.json({ success: true, message: 'Đơn đã hoàn thành!' });
        } catch (error) {
            next(error);
        }
    },

    /**
     * PUT /api/dine-in/staff/tables
     * Staff - Cập nhật số lượng bàn của quán
     */
    updateTables: async (req, res, next) => {
        try {
            const { soBan } = req.body;
            if (!soBan || Number(soBan) <= 0) {
                return res.status(400).json({ success: false, message: 'Số bàn không hợp lệ.' });
            }

            const [canteen] = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );

            if (!canteen) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }

            await db.query(
                'UPDATE gianhang SET soBan = ? WHERE maGianHang = ?',
                [Number(soBan), canteen.maGianHang]
            );

            return res.json({ success: true, message: 'Đã cập nhật số lượng bàn ăn.' });
        } catch (error) {
            next(error);
        }
    },

    /**
     * GET /api/dine-in/payment-status/:maDonHang
     * Lấy trạng thái thanh toán đơn hàng (public cho web).
     */
    getPaymentStatusPublic: async (req, res, next) => {
        try {
            const { maDonHang } = req.params;
            const [payment] = await db.query(
                `SELECT d.trangThaiThanhToan, d.phuongThucThanhToan, d.tongTien
                 FROM donhang d
                 WHERE d.maDonHang = ?`,
                [Number(maDonHang)]
            );

            if (!payment) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
            }

            return res.json({
                success: true,
                data: {
                    trangThaiThanhToan: payment.trangThaiThanhToan,
                    phuongThucThanhToan: payment.phuongThucThanhToan,
                    tongTien: payment.tongTien
                }
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * GET /api/dine-in/table-bill/:maGianHang/:soBanAn
     * Lấy tổng hợp hóa đơn các món đã gọi của bàn hôm nay chưa thanh toán.
     */
    getTableBillPublic: async (req, res, next) => {
        try {
            const { maGianHang, soBanAn } = req.params;

            // Tìm các đơn hàng dineIn chưa thanh toán trong ngày hôm nay của bàn này tại quán này
            const orders = await db.query(
                `SELECT d.maDonHang, d.tongTien, d.trangThaiDonHang, d.trangThaiThanhToan, d.thoiGianDat, d.tenKhachDineIn
                 FROM donhang d
                 JOIN chitietdonhang ctdh ON d.maDonHang = ctdh.maDonHang
                 JOIN monan ma ON ctdh.maMonAn = ma.maMonAn
                 WHERE d.loaiDonHang = 'dineIn' 
                   AND d.soBanAn = ? 
                   AND ma.maGianHang = ?
                   AND d.trangThaiThanhToan = 'pending'
                   AND d.trangThaiDonHang != 'daHuy'
                   AND d.thoiGianDat >= NOW() - INTERVAL 12 HOUR
                 GROUP BY d.maDonHang`,
                [Number(soBanAn), Number(maGianHang)]
            );

            if (!orders || orders.length === 0) {
                return res.json({ success: true, data: { items: [], totalQty: 0, totalPrice: 0 } });
            }

            const orderIds = orders.map(o => o.maDonHang);

            // Lấy danh sách món ăn gom nhóm lũy kế
            const items = await db.query(
                `SELECT ma.maMonAn, ma.tenMonAn, SUM(ctdh.soLuong) as soLuong, ctdh.giaTien
                 FROM chitietdonhang ctdh
                 JOIN monan ma ON ctdh.maMonAn = ma.maMonAn
                 WHERE ctdh.maDonHang IN (?)
                 GROUP BY ma.maMonAn, ctdh.giaTien`,
                [orderIds]
            );

            let totalQty = 0;
            let totalPrice = 0;
            items.forEach(item => {
                item.soLuong = Number(item.soLuong);
                totalQty += item.soLuong;
                totalPrice += item.soLuong * item.giaTien;
            });

            return res.json({
                success: true,
                data: {
                    orders: orders,
                    items: items,
                    totalQty,
                    totalPrice
                }
            });
        } catch (error) {
            next(error);
        }
    },
};

module.exports = DineInController;
module.exports = DineInController;
