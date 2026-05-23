// controllers/reviewController.js
const path = require('path');
const fs = require('fs');
const ReviewModel = require('../models/reviewModel');

const ReviewController = {

    // GET /api/reviews/order/:id/items
    getItemsForReview: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const maDonHang = Number(req.params.id);
            const items = await ReviewModel.getItemsForReview(maDonHang, maTaiKhoan);
            if (items === null) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
            if (items.notDelivered) return res.status(400).json({ success: false, message: 'Chỉ có thể đánh giá đơn đã giao.' });
            res.status(200).json({ success: true, data: items });
        } catch (error) { next(error); }
    },

    // POST /api/reviews/order/:id
    submitReview: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const maDonHang = Number(req.params.id);
            const { reviews } = req.body;
            if (!reviews || !Array.isArray(reviews) || reviews.length === 0) {
                return res.status(400).json({ success: false, message: 'Vui lòng cung cấp đánh giá.' });
            }
            await ReviewModel.submitReview(maDonHang, maTaiKhoan, reviews);
            res.status(200).json({ success: true, message: 'Đánh giá của bạn đã được ghi nhận. Cảm ơn!' });
        } catch (error) {
            if (error.message.includes('Chỉ có thể') || error.message.includes('Không tìm thấy') || error.message.includes('đã được đánh giá')) {
                return res.status(400).json({ success: false, message: error.message });
            }
            next(error);
        }
    },

    // GET /api/reviews/order/:id/status
    getReviewStatus: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const maDonHang = Number(req.params.id);
            const status = await ReviewModel.getReviewStatus(maDonHang, maTaiKhoan);
            if (!status) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
            res.status(200).json({ success: true, data: status });
        } catch (error) { next(error); }
    },

    // GET /api/reviews/my  — lấy tất cả đánh giá của user hiện tại
    getMyReviews: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { query } = require('../config/db');
            const rows = await query(
                `SELECT
                    dg.maDanhGia,
                    dg.soSao,
                    dg.binhLuan,
                    dg.hinhAnhDanhGia,
                    dg.thoiGianDanhGia,
                    m.maMonAn,
                    m.tenMonAn,
                    m.hinhAnh         AS anhMonAn,
                    g.tenGianHang
                 FROM danhgia dg
                 JOIN monan   m  ON m.maMonAn    = dg.maMonAn
                 JOIN gianhang g ON g.maGianHang = m.maGianHang
                 JOIN donhang  d ON d.maDonHang  = dg.maDonHang
                 WHERE d.maTaiKhoan = ?
                 ORDER BY dg.thoiGianDanhGia DESC`,
                [maTaiKhoan]
            );
            const parsed = rows.map(r => {
                let images = [];
                if (r.hinhAnhDanhGia) {
                    try {
                        const p = JSON.parse(r.hinhAnhDanhGia);
                        images = Array.isArray(p) ? p : [p];
                    } catch (e) {
                        images = [r.hinhAnhDanhGia];
                    }
                }
                return { ...r, hinhAnhDanhGia: images };
            });
            res.status(200).json({ success: true, data: parsed });
        } catch (error) { next(error); }
    },

    // GET /api/reviews/order/:id
    getReviewByOrder: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const maDonHang = Number(req.params.id);
            const reviews = await ReviewModel.getReviewByOrder(maDonHang, maTaiKhoan);
            res.status(200).json({ success: true, data: reviews });
        } catch (error) { next(error); }
    },

    // GET /api/reviews/dish/:dishId           ← PUBLIC (không cần token)
    // ?limit=2  để lấy preview 2 cái
    getDishReviews: async (req, res, next) => {
        try {
            const maMonAn = Number(req.params.dishId);
            const limit = req.query.limit ? Number(req.query.limit) : null;
            const reviews = await ReviewModel.getDishReviews(maMonAn, limit);
            res.status(200).json({ success: true, data: reviews });
        } catch (error) { next(error); }
    },

    // POST /api/reviews/upload-image          ← yêu cầu token
    // multipart/form-data  field: "image"
    uploadReviewImage: async (req, res, next) => {
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'Không có file nào được gửi lên.' });
            }
            const imageUrl = `/uploads/reviews/${req.file.filename}`;
            res.status(200).json({ success: true, imageUrl });
        } catch (error) { next(error); }
    },
};

module.exports = ReviewController;
