// models/reviewModel.js
const db = require('../config/db');

const ReviewModel = {

    // 1. Lấy danh sách món ăn trong đơn hàng cần đánh giá
    getItemsForReview: async (maDonHang, maTaiKhoan) => {
        const orders = await db.query(
            `SELECT maDonHang, trangThaiDonHang 
             FROM donhang 
             WHERE maDonHang = ? AND maTaiKhoan = ?`,
            [maDonHang, maTaiKhoan]
        );
        if (!orders[0]) return null;
        if (orders[0].trangThaiDonHang !== 'daGiao') return { notDelivered: true };

        const items = await db.query(
            `SELECT ct.maMonAn, m.tenMonAn, m.hinhAnh, ct.soLuong, ct.giaTien,
                    g.tenGianHang,
                    (SELECT dg.soSao FROM danhgia dg 
                     WHERE dg.maDonHang = ct.maDonHang AND dg.maMonAn = ct.maMonAn 
                     LIMIT 1) as daDanhGia
             FROM chitietdonhang ct
             JOIN monan m ON ct.maMonAn = m.maMonAn
             JOIN gianhang g ON m.maGianHang = g.maGianHang
             WHERE ct.maDonHang = ?`,
            [maDonHang]
        );
        return items;
    },

    // 2. Gửi đánh giá + tính lại diemDanhGia & luotDanhGia cho từng món
    submitReview: async (maDonHang, maTaiKhoan, reviews) => {
        const orders = await db.query(
            `SELECT maDonHang, trangThaiDonHang 
             FROM donhang 
             WHERE maDonHang = ? AND maTaiKhoan = ?`,
            [maDonHang, maTaiKhoan]
        );
        if (!orders[0]) throw new Error('Không tìm thấy đơn hàng.');
        if (orders[0].trangThaiDonHang !== 'daGiao') {
            throw new Error('Chỉ có thể đánh giá đơn đã giao.');
        }

        const connection = await db.getPool().getConnection();
        try {
            await connection.beginTransaction();

            const ratedMonAnIds = [];

            for (const rev of reviews) {
                const { maMonAn, soSao, binhLuan, hinhAnhDanhGia } = rev;
                if (!soSao || soSao < 1 || soSao > 5) continue;

                const [existingRows] = await connection.execute(
                    'SELECT maDanhGia FROM danhgia WHERE maDonHang = ? AND maMonAn = ?',
                    [maDonHang, maMonAn]
                );
                const existing = existingRows[0];

                if (existing) {
                    throw new Error('Đơn hàng đã được đánh giá, không thể đánh giá lại!');
                }

                // Lưu ảnh dưới dạng JSON string nếu có
                const hinhAnhJson = hinhAnhDanhGia && Array.isArray(hinhAnhDanhGia) && hinhAnhDanhGia.length > 0
                    ? JSON.stringify(hinhAnhDanhGia)
                    : null;

                await connection.execute(
                    `INSERT INTO danhgia (maDonHang, maMonAn, soSao, binhLuan, hinhAnhDanhGia, thoiGianDanhGia)
                     VALUES (?, ?, ?, ?, ?, NOW())`,
                    [maDonHang, maMonAn, soSao, binhLuan || null, hinhAnhJson]
                );

                ratedMonAnIds.push(Number(maMonAn));
            }

            // Tính lại AVG và COUNT → cập nhật monan
            for (const maMonAn of ratedMonAnIds) {
                const [statsRows] = await connection.execute(
                    `SELECT ROUND(AVG(soSao), 1) as diem, COUNT(*) as luot 
                     FROM danhgia WHERE maMonAn = ?`,
                    [maMonAn]
                );
                const stats = statsRows[0];
                if (stats) {
                    await connection.execute(
                        `UPDATE monan SET diemDanhGia = ?, luotDanhGia = ? WHERE maMonAn = ?`,
                        [parseFloat(stats.diem) || 0.0, Number(stats.luot) || 0, maMonAn]
                    );
                }
            }

            await connection.commit();
            return true;
        } catch (err) {
            await connection.rollback();
            throw err;
        } finally {
            connection.release();
        }
    },

    // 3. Kiểm tra đơn đã đánh giá chưa
    getReviewStatus: async (maDonHang, maTaiKhoan) => {
        const orders = await db.query(
            `SELECT d.maDonHang, d.trangThaiDonHang,
                    COUNT(ct.maMonAn) as tongMon,
                    COUNT(dg.maDanhGia) as daGuiDanhGia
             FROM donhang d
             JOIN chitietdonhang ct ON d.maDonHang = ct.maDonHang
             LEFT JOIN danhgia dg ON dg.maDonHang = d.maDonHang AND dg.maMonAn = ct.maMonAn
             WHERE d.maDonHang = ? AND d.maTaiKhoan = ?
             GROUP BY d.maDonHang`,
            [maDonHang, maTaiKhoan]
        );
        return orders[0] || null;
    },

    // 4. Lấy đánh giá của một đơn để hiển thị lại
    getReviewByOrder: async (maDonHang, maTaiKhoan) => {
        const rows = await db.query(
            `SELECT dg.maDanhGia, dg.maMonAn, dg.soSao, dg.binhLuan, dg.hinhAnhDanhGia, dg.thoiGianDanhGia,
                    m.tenMonAn, m.hinhAnh
             FROM danhgia dg
             JOIN monan m ON dg.maMonAn = m.maMonAn
             JOIN donhang d ON dg.maDonHang = d.maDonHang
             WHERE dg.maDonHang = ? AND d.maTaiKhoan = ?`,
            [maDonHang, maTaiKhoan]
        );
        return rows;
    },

    // 5. [MỚI] Lấy đánh giá theo món ăn (cho trang chi tiết & all reviews)
    getDishReviews: async (maMonAn, limit = null) => {
        let sql = `
            SELECT 
                dg.maDanhGia,
                dg.soSao,
                dg.binhLuan,
                dg.hinhAnhDanhGia,
                dg.thoiGianDanhGia,
                tk.hoTen       AS tenNguoiDung,
                tk.anhDaiDien  AS anhDaiDienNguoiDung
            FROM danhgia dg
            JOIN donhang d   ON dg.maDonHang = d.maDonHang
            JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
            WHERE dg.maMonAn = ?
            ORDER BY dg.thoiGianDanhGia DESC
        `;
        const params = [maMonAn];
        if (limit) {
            sql += ' LIMIT ?';
            params.push(Number(limit));
        }
        const rows = await db.query(sql, params);
        // Parse hinhAnhDanhGia: hỗ trợ cả JSON array hoặc chuỗi đơn (để dễ nhập tay trong DB)
        return rows.map(r => {
            let images = [];
            if (r.hinhAnhDanhGia) {
                try {
                    const parsed = JSON.parse(r.hinhAnhDanhGia);
                    images = Array.isArray(parsed) ? parsed : [parsed];
                } catch (e) {
                    // Nếu không phải JSON (nhập tay), coi cả chuỗi đó là 1 đường dẫn ảnh
                    images = [r.hinhAnhDanhGia];
                }
            }
            return { ...r, hinhAnhDanhGia: images };
        });
    },
};

module.exports = ReviewModel;
