require('dotenv').config();
const db = require('./src/config/db');

async function migrate() {
    try {
        await db.query(
            "ALTER TABLE donhang ADD COLUMN loaiDonHang VARCHAR(20) NOT NULL DEFAULT 'delivery'"
        );
        console.log('OK - Đã thêm cột loaiDonHang vào bảng donhang');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.log('Cột loaiDonHang đã tồn tại, bỏ qua.');
        } else {
            console.error('Lỗi:', e.message);
        }
    }
    process.exit(0);
}

migrate();
