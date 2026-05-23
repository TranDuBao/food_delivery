require('dotenv').config();
const db = require('./src/config/db');

async function migrate() {
    try {
        // Thêm cột soLanDaDung vào bảng giamgia
        await db.query(`
            ALTER TABLE giamgia
            ADD COLUMN IF NOT EXISTS soLanDaDung INT NOT NULL DEFAULT 0
                COMMENT 'Số lần voucher đã được dùng thực tế khi checkout'
        `);
        console.log('OK - Đã thêm cột soLanDaDung vào bảng giamgia');

        // Cập nhật lại soLanDaDung dựa vào đơn hàng đã dùng voucher (nếu có cột maGiamGia trong donhang)
        const cols = await db.query("SHOW COLUMNS FROM donhang LIKE 'maGiamGia'");
        if (cols.length > 0) {
            await db.query(`
                UPDATE giamgia gg
                SET gg.soLanDaDung = (
                    SELECT COUNT(DISTINCT d.maDonHang)
                    FROM donhang d
                    WHERE d.maGiamGia = gg.maGiamGia
                      AND d.trangThaiDonHang NOT IN ('daHuy')
                )
            `);
            console.log('OK - Đã sync soLanDaDung từ lịch sử đơn hàng');
        }

        // Thêm cột maGiamGia vào donhang nếu chưa có
        const hasMaGiamGia = await db.query("SHOW COLUMNS FROM donhang LIKE 'maGiamGia'");
        if (hasMaGiamGia.length === 0) {
            await db.query(`
                ALTER TABLE donhang
                ADD COLUMN maGiamGia INT NULL DEFAULT NULL
                    COMMENT 'FK → giamgia.maGiamGia, null nếu không dùng voucher',
                ADD COLUMN soTienGiam DECIMAL(15,2) NOT NULL DEFAULT 0
                    COMMENT 'Số tiền đã giảm từ voucher'
            `);
            console.log('OK - Đã thêm cột maGiamGia và soTienGiam vào bảng donhang');
        } else {
            console.log('Cột maGiamGia đã tồn tại trong donhang, bỏ qua.');
            // Thêm soTienGiam nếu chưa có
            const hasSoTienGiam = await db.query("SHOW COLUMNS FROM donhang LIKE 'soTienGiam'");
            if (hasSoTienGiam.length === 0) {
                await db.query(`ALTER TABLE donhang ADD COLUMN soTienGiam DECIMAL(15,2) NOT NULL DEFAULT 0`);
                console.log('OK - Đã thêm cột soTienGiam vào bảng donhang');
            }
        }

    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.log('Column already exists, skipping.');
        } else {
            console.error('Lỗi:', e.message);
        }
    }
    process.exit(0);
}

migrate();
