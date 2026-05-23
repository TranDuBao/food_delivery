// routes/reviewRoutes.js
const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const ReviewController = require('../controllers/reviewController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// ─── Multer setup cho ảnh đánh giá ───────────────────────────────────────────
const uploadDir = path.resolve(__dirname, '../../uploads/reviews');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadDir),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `review_${Date.now()}${ext}`);
    },
});
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (_req, file, cb) => {
        if (file.mimetype.startsWith('image/')) cb(null, true);
        else cb(new Error('Chỉ chấp nhận file ảnh.'));
    },
});
// ─────────────────────────────────────────────────────────────────────────────

// PUBLIC — lấy đánh giá theo món ăn (không cần token)
router.get('/dish/:dishId', ReviewController.getDishReviews);

// Tất cả routes bên dưới yêu cầu token khách hàng
router.use(verifyToken);
router.use(authorizeRole([1]));

// Lấy tất cả đánh giá của chính mình
router.get('/my', ReviewController.getMyReviews);

// Upload ảnh đánh giá
router.post('/upload-image', upload.single('image'), ReviewController.uploadReviewImage);

// Lấy món cần rate trong đơn
router.get('/order/:id/items', ReviewController.getItemsForReview);

// Kiểm tra đơn đã được đánh giá chưa
router.get('/order/:id/status', ReviewController.getReviewStatus);

// Xem đánh giá của đơn
router.get('/order/:id', ReviewController.getReviewByOrder);

// Gửi đánh giá
router.post('/order/:id', ReviewController.submitReview);

module.exports = router;
