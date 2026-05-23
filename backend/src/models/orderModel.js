// models/orderModel.js
const db = require('../config/db');

const OrderModel = {
    // 1. Tạo đơn hàng mới với kiểm tra và trừ tồn kho tự động
    createOrder: async (orderData) => {
        const { maTaiKhoan, maToaNha, maPhong, tongTien, items,
                maGiamGia = null, soTienGiam = 0 } = orderData;

        return db.withTransaction(async (connection) => {
            // ── Bước 1: Kiểm tra tồn kho cho từng món ──
            for (const item of items) {
                const [stockRows] = await connection.execute(
                    'SELECT soLuongTon, tenMonAn, daXoa, trangThai FROM monan WHERE maMonAn = ?',
                    [item.maMonAn]
                );

                if (!stockRows || stockRows.length === 0) {
                    throw new Error(`Món ăn (ID: ${item.maMonAn}) không tồn tại.`);
                }
                const dish = stockRows[0];
                if (dish.daXoa === 1) {
                    throw new Error(`"${dish.tenMonAn}" đã ngừng bán.`);
                }
                const currentStock = dish.soLuongTon ?? 99;
                if (currentStock < item.soLuong) {
                    throw new Error(`"${dish.tenMonAn}" chỉ còn ${currentStock} phần. Vui lòng giảm số lượng.`);
                }
            }

            // ── Bước 2: Tạo bản ghi donhang (kèm voucher nếu có) ──
            const [orderResult] = await connection.execute(
                `INSERT INTO donhang 
                    (maTaiKhoan, maToaNha, maPhong, tongTien, maGiamGia, soTienGiam,
                     trangThaiDonHang, thoiGianDat) 
                 VALUES (?, ?, ?, ?, ?, ?, 'choGhepDon', NOW())`,
                [maTaiKhoan, maToaNha, maPhong, tongTien, maGiamGia, soTienGiam]
            );
            const newOrderId = orderResult.insertId;

            // ── Bước 3: Tạo chitietdonhang (1 dòng / 1 phần ăn) + trừ tồn kho ──
            for (const item of items) {
                for (let i = 0; i < item.soLuong; i++) {
                    await connection.execute(
                        `INSERT INTO chitietdonhang (maDonHang, maMonAn, soLuong, giaTien, trangThaiMon) VALUES (?, ?, 1, ?, 'pending')`,
                        [newOrderId, item.maMonAn, item.giaTien]
                    );
                }

                const [updateResult] = await connection.execute(
                    'UPDATE monan SET soLuongTon = soLuongTon - ? WHERE maMonAn = ? AND soLuongTon >= ?',
                    [item.soLuong, item.maMonAn, item.soLuong]
                );
                if (updateResult.affectedRows === 0) {
                    throw new Error(`Lỗi tồn kho khi trừ món (ID: ${item.maMonAn}). Vui lòng thử lại.`);
                }
            }

            // ── Bước 4: Xóa giỏ hàng sau khi đặt thành công ──
            await connection.execute(
                'DELETE FROM giohang WHERE maTaiKhoan = ?',
                [maTaiKhoan]
            );

            return newOrderId;
        });
    },

    // 2. Lấy các đơn đang chờ ghép trong cùng khu vực (maToaNha)
    getAreaOrders: async (maToaNha) => {
        const rows = await db.query(`
            SELECT d.maDonHang, d.trangThaiDonHang, d.thoiGianDat, d.maTaiKhoan,
                   tn.tenToaNha, p.tenPhong,
                   tk.hoTen as tenKhach,
                   GROUP_CONCAT(m.tenMonAn ORDER BY m.tenMonAn SEPARATOR ', ') as danhSachMon,
                   MAX(m.hinhAnh) as hinhAnhDauTien
            FROM donhang d
            JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
            JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
            LEFT JOIN phong p ON d.maPhong = p.maPhong
            WHERE d.maToaNha = ?
              AND d.trangThaiDonHang IN ('choGhepDon', 'choXacNhan', 'dangChuanBi')
            GROUP BY d.maDonHang
            ORDER BY d.thoiGianDat ASC
        `, [maToaNha]);
        return rows;
    },

    // 3. Lấy lịch sử đơn của user (kèm trạng thái đã đánh giá)
    getMyOrders: async (maTaiKhoan) => {
        const rows = await db.query(`
            SELECT d.maDonHang, d.maToaNha, tn.tenToaNha, p.tenPhong,
                   d.tongTien, d.trangThaiDonHang, d.thoiGianDat,
                   GROUP_CONCAT(DISTINCT m.tenMonAn ORDER BY m.tenMonAn SEPARATOR ', ') as danhSachMon,
                   MIN(m.maMonAn) as maMonAnDauTien,
                   MIN(m.tenMonAn) as tenMonAnDauTien,
                   GROUP_CONCAT(DISTINCT m.maMonAn ORDER BY m.maMonAn SEPARATOR ',') as dsMonAn,
                   (
                       SELECT COUNT(*)
                       FROM chitietdonhang ct2
                       WHERE ct2.maDonHang = d.maDonHang
                   ) as tongMon,
                   (
                       SELECT COUNT(*)
                       FROM danhgia dg
                       JOIN chitietdonhang ct3 ON dg.maMonAn = ct3.maMonAn
                       WHERE dg.maDonHang = d.maDonHang AND ct3.maDonHang = d.maDonHang
                   ) as soMonDaDanhGia,
                   MAX(m.hinhAnh) as hinhAnhDauTien
            FROM donhang d
            JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
            LEFT JOIN phong p ON d.maPhong = p.maPhong
            WHERE d.maTaiKhoan = ?
            GROUP BY d.maDonHang
            ORDER BY d.thoiGianDat DESC
            LIMIT 20
        `, [maTaiKhoan]);
        return rows;
    },

    // 4. Nhân viên gian hàng đánh dấu đơn đã xong
    markOrderReady: async (maDonHang) => {
        const result = await db.query(
            "UPDATE donhang SET trangThaiDonHang = 'choGiaoHang' WHERE maDonHang = ? AND trangThaiDonHang = 'dangChuanBi'",
            [maDonHang]
        );
        return result.affectedRows > 0;
    },

    // 5. Kiểm tra và cập nhật nhóm sang 'dangGiao' nếu tất cả đơn trong nhóm đã xong
    checkAndUpdateGroup: async (maDonHang) => {
        const rows = await db.query(
            'SELECT maNhomGiaoHang FROM donhang WHERE maDonHang = ?',
            [maDonHang]
        );
        if (!rows[0] || !rows[0].maNhomGiaoHang) return false;

        const maNhom = rows[0].maNhomGiaoHang;
        const stats = await db.query(`
            SELECT 
                COUNT(*) as tongDon,
                SUM(CASE WHEN trangThaiDonHang = 'choGiaoHang' THEN 1 ELSE 0 END) as donXong
            FROM donhang WHERE maNhomGiaoHang = ?
        `, [maNhom]);

        const { tongDon, donXong } = stats[0];
        if (Number(tongDon) > 0 && Number(tongDon) === Number(donXong)) {
            await db.query(
                "UPDATE nhomgiaohang SET trangThaiNhom = 'dangGiao' WHERE maNhomGiaoHang = ?",
                [maNhom]
            );
            return true;
        }
        return false;
    },

    // ============ CronJob helpers ============

    getPendingGroups: async () => {
        return db.query(`
            SELECT maToaNha, COUNT(*) as slDon, MIN(thoiGianDat) as thoiGianDatCuNhat
            FROM donhang
            WHERE trangThaiDonHang = 'choGhepDon'
            GROUP BY maToaNha
            HAVING TIMESTAMPDIFF(MINUTE, MIN(thoiGianDat), NOW()) >= 5
        `);
    },

    getPendingOrdersByGroup: async (maToaNha) => {
        const rows = await db.query(
            "SELECT maDonHang FROM donhang WHERE trangThaiDonHang = 'choGhepDon' AND maToaNha = ?",
            [maToaNha]
        );
        return rows.map(r => r.maDonHang);
    },

    cancelOrders: async (orderIds) => {
        if (!orderIds || orderIds.length === 0) return;
        return db.withTransaction(async (connection) => {
            // Lấy danh sách món ăn để hoàn lại số lượng tồn kho
            // Mỗi dòng chitietdonhang có soLuong=1, nên SUM(soLuong) = số phần cần hoàn lại
            const [items] = await connection.query(
                "SELECT maMonAn, SUM(soLuong) AS soLuong FROM chitietdonhang WHERE maDonHang IN (?) GROUP BY maMonAn",
                [orderIds]
            );

            // Hoàn lại số lượng tồn kho cho từng món
            for (const item of items) {
                await connection.execute(
                    "UPDATE monan SET soLuongTon = soLuongTon + ? WHERE maMonAn = ?",
                    [item.soLuong, item.maMonAn]
                );
            }

            // Cập nhật trạng thái đơn hàng thành đã hủy
            await connection.query(
                "UPDATE donhang SET trangThaiDonHang = 'daHuy' WHERE maDonHang IN (?)",
                [orderIds]
            );
        });
    },

    groupOrdersToDelivery: async (maToaNha, orderIds) => {
        return db.withTransaction(async (connection) => {
            const [nhomRes] = await connection.execute(
                "INSERT INTO nhomgiaohang (maToaNha, thoiGianTaoNhom, trangThaiNhom) VALUES (?, NOW(), 'choGiaoHang')",
                [maToaNha]
            );
            const maNhom = nhomRes.insertId;

            await connection.query(
                "UPDATE donhang SET maNhomGiaoHang = ?, trangThaiDonHang = 'choXacNhan' WHERE maDonHang IN (?)",
                [maNhom, orderIds]
            );

            return maNhom;
        });
    },

    getOrdersForStaff: async (maGianHang) => {
        return db.query(`
            SELECT DISTINCT d.maDonHang, tn.tenToaNha, p.tenPhong,
                   d.trangThaiDonHang, d.thoiGianDat, d.maNhomGiaoHang,
                   d.tongTien, d.phuongThucThanhToan, d.trangThaiThanhToan,
                   tk.hoTen as tenKhach, tk.soDienThoai,
                   d.loaiDonHang, d.soBanAn, d.tenKhachDineIn,
                   GROUP_CONCAT(m.tenMonAn, ' x', ct.soLuong ORDER BY m.tenMonAn SEPARATOR ', ') as danhSachMon
            FROM donhang d
            JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
            LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
            LEFT JOIN phong p ON d.maPhong = p.maPhong
            WHERE m.maGianHang = ?
              AND (d.loaiDonHang IS NULL OR d.loaiDonHang != 'dineIn')
              AND d.trangThaiDonHang IN ('choXacNhan', 'dangChuanBi', 'choGiaoHang', 'delivered', 'daGiao')
            GROUP BY d.maDonHang
            ORDER BY FIELD(d.trangThaiDonHang, 'choXacNhan', 'dangChuanBi', 'choGiaoHang', 'delivered', 'daGiao'), d.thoiGianDat DESC
        `, [maGianHang]);
    },

    // Nhân viên nhấn "Bắt đầu làm" -> chuyển từ 'choXacNhan' sang 'dangChuanBi'
    startPreparingOrder: async (maDonHang, maGianHang) => {
        const result = await db.query(
            "UPDATE donhang d JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang JOIN monan m ON ct.maMonAn = m.maMonAn SET d.trangThaiDonHang = 'dangChuanBi' WHERE d.maDonHang = ? AND m.maGianHang = ? AND d.trangThaiDonHang = 'choXacNhan'",
            [maDonHang, maGianHang]
        );
        if (result.affectedRows > 0) {
            // Đặt lại trangThaiMon = 'pending' cho các món của gian hàng này trong đơn
            await db.query(
                "UPDATE chitietdonhang ct JOIN monan m ON ct.maMonAn = m.maMonAn SET ct.trangThaiMon = 'pending' WHERE ct.maDonHang = ? AND m.maGianHang = ?",
                [maDonHang, maGianHang]
            );
        }
        return result.affectedRows > 0;
    },

    // ============ Kitchen Display System (KDS) ============

    getKDSData: async (maGianHang) => {
        // Lấy chi tiết từng dòng để controller gộp theo (maDonHang, maMonAn)
        return db.query(`
            SELECT ct.maChiTietDonHang, d.maDonHang, m.maMonAn, m.tenMonAn, m.hinhAnh, 
                   ct.soLuong, ct.trangThaiMon, ct.ghiChu, tk.hoTen as tenKhach,
                   d.loaiDonHang, d.soBanAn, d.tenKhachDineIn
            FROM donhang d
            JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
            WHERE m.maGianHang = ? 
              AND d.trangThaiDonHang = 'dangChuanBi'
            ORDER BY d.maDonHang ASC, m.maMonAn ASC
        `, [maGianHang]);
    },

    // Bếp quẹt đánh dấu món đã nấu xong
    markKDSItemReady: async (maGianHang, maChiTietDonHang) => {
        // Cập nhật trạng thái của chi tiết đơn hàng thuộc đơn đang chuẩn bị
        const result = await db.query(`
            UPDATE chitietdonhang ct
            JOIN donhang d ON ct.maDonHang = d.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            SET ct.trangThaiMon = 'ready'
            WHERE m.maGianHang = ? 
              AND ct.maChiTietDonHang = ?
              AND d.trangThaiDonHang = 'dangChuanBi'
              AND (ct.trangThaiMon = 'pending' OR ct.trangThaiMon IS NULL)
        `, [maGianHang, maChiTietDonHang]);

        // Find orders that are ready and update them to choGiaoHang
        await db.query(`
            UPDATE donhang d
            JOIN (
                SELECT ct.maDonHang
                FROM chitietdonhang ct
                GROUP BY ct.maDonHang
                HAVING SUM(CASE WHEN ct.trangThaiMon != 'ready' THEN 1 ELSE 0 END) = 0
            ) AS ready_orders ON d.maDonHang = ready_orders.maDonHang
            SET d.trangThaiDonHang = 'choGiaoHang'
            WHERE d.trangThaiDonHang = 'dangChuanBi'
        `);

        // Check if groups are fully ready and update their status
        await db.query(`
            UPDATE nhomgiaohang ng
            JOIN (
                SELECT d.maNhomGiaoHang
                FROM donhang d
                WHERE d.maNhomGiaoHang IS NOT NULL
                GROUP BY d.maNhomGiaoHang
                HAVING SUM(CASE WHEN d.trangThaiDonHang != 'choGiaoHang' THEN 1 ELSE 0 END) = 0
            ) AS ready_groups ON ng.maNhomGiaoHang = ready_groups.maNhomGiaoHang
            SET ng.trangThaiNhom = 'dangGiao'
            WHERE ng.trangThaiNhom != 'dangGiao'
        `);

        return result.affectedRows > 0;
    },

    getStatistics: async (maGianHang, period, dateStr) => {
        const targetDate = dateStr ? new Date(dateStr) : new Date();

        let startDate, endDate, prevStartDate, prevEndDate;
        let groupByFormat;

        if (period === 'year') {
            startDate = new Date(targetDate.getFullYear(), 0, 1);
            endDate = new Date(targetDate.getFullYear(), 11, 31, 23, 59, 59);
            prevStartDate = new Date(targetDate.getFullYear() - 1, 0, 1);
            prevEndDate = new Date(targetDate.getFullYear() - 1, 11, 31, 23, 59, 59);
            groupByFormat = '%Y-%m'; // group by month
        } else if (period === 'month') {
            startDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
            endDate = new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59);
            prevStartDate = new Date(targetDate.getFullYear(), targetDate.getMonth() - 1, 1);
            prevEndDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), 0, 23, 59, 59);
            groupByFormat = '%Y-%m-%d'; // group by day
        } else {
            // default to day
            startDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());
            endDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 23, 59, 59);
            prevStartDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() - 1);
            prevEndDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() - 1, 23, 59, 59);
            groupByFormat = '%H'; // group by hour
        }

        const getStatsQuery = async (start, end) => {
            const rows = await db.query(`
                SELECT 
                    DATE_FORMAT(d.thoiGianDat, ?) as label,
                    COUNT(DISTINCT d.maDonHang) as orders,
                    SUM(ct.soLuong * ct.giaTien) as revenue
                FROM donhang d
                JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
                JOIN monan m ON ct.maMonAn = m.maMonAn
                WHERE m.maGianHang = ? 
                  AND d.trangThaiDonHang IN ('choGiaoHang', 'delivered', 'daGiao')
                  AND d.thoiGianDat BETWEEN ? AND ?
                GROUP BY label
                ORDER BY label ASC
            `, [groupByFormat, maGianHang, start, end]);

            let totalOrders = 0;
            let totalRevenue = 0;
            const chartData = rows.map(r => {
                totalOrders += r.orders;
                totalRevenue += Number(r.revenue);
                return { label: r.label, revenue: Number(r.revenue), orders: r.orders };
            });

            return { totalOrders, totalRevenue, chartData };
        };

        const current = await getStatsQuery(startDate, endDate);
        const previous = await getStatsQuery(prevStartDate, prevEndDate);

        let revenueGrowth = 0;
        if (previous.totalRevenue > 0) {
            revenueGrowth = ((current.totalRevenue - previous.totalRevenue) / previous.totalRevenue) * 100;
        } else if (current.totalRevenue > 0) {
            revenueGrowth = 100;
        }

        // Get detailed order status counts
        const statusRows = await db.query(`
            SELECT 
                d.trangThaiDonHang,
                COUNT(*) as count
            FROM donhang d
            JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
            JOIN monan m ON ct.maMonAn = m.maMonAn
            WHERE m.maGianHang = ?
              AND d.thoiGianDat BETWEEN ? AND ?
            GROUP BY d.trangThaiDonHang
        `, [maGianHang, startDate, endDate]);

        let successOrders = 0, cancelledOrders = 0;
        for (const r of statusRows) {
            if (['choGiaoHang', 'delivered', 'daGiao'].includes(r.trangThaiDonHang)) successOrders += Number(r.count);
            if (r.trangThaiDonHang === 'daHuy') cancelledOrders += Number(r.count);
        }

        // Get top selling dishes
        const topDishes = await db.query(`
            SELECT 
                m.tenMonAn as name,
                m.hinhAnh as image,
                SUM(ct.soLuong) as totalSold,
                SUM(ct.soLuong * ct.giaTien) as totalRevenue
            FROM chitietdonhang ct
            JOIN monan m ON ct.maMonAn = m.maMonAn
            JOIN donhang d ON ct.maDonHang = d.maDonHang
            WHERE m.maGianHang = ?
              AND d.trangThaiDonHang IN ('choGiaoHang', 'delivered', 'daGiao')
              AND d.thoiGianDat BETWEEN ? AND ?
            GROUP BY m.maMonAn, m.tenMonAn, m.hinhAnh
            ORDER BY totalSold DESC
            LIMIT 5
        `, [maGianHang, startDate, endDate]);

        return {
            period: period || 'day',
            startDate,
            endDate,
            current,
            previous: {
                totalOrders: previous.totalOrders,
                totalRevenue: previous.totalRevenue,
            },
            performance: {
                revenueGrowth: parseFloat(revenueGrowth.toFixed(2))
            },
            orderBreakdown: {
                success: successOrders,
                cancelled: cancelledOrders,
                total: current.totalOrders,
            },
            topDishes: topDishes.map(d => ({
                name: d.name,
                image: d.image,
                totalSold: Number(d.totalSold),
                totalRevenue: Number(d.totalRevenue),
            })),
        };
    }
};

module.exports = OrderModel;
