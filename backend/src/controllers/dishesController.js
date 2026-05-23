// controllers/monAnController.js
const MonAnModel = require('../models/dishesModel');
const { saveCroppedDishImage } = require('../config/upload');

// Helper để gắn host URL vào ảnh
const buildImageUrl = (req, path) => {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    return `${req.protocol}://${req.get('host')}${path}`;
};

const MonAnController = {
    // ==========================================
    // NHÓM API KHÁCH HÀNG (Chỉ Xem)
    // ==========================================
    getAllFoods: async (req, res, next) => {
        try {
            const keyword = req.query.keyword || ''; 
            const limit = req.query.limit || null;
            const maDanhMuc = req.query.maDanhMuc || null;

            const foods = await MonAnModel.getAll(keyword, limit, maDanhMuc);

            const mapped = foods.map(f => ({
                id: f.maMonAn,
                name: f.tenMonAn,
                price: Number(f.giaTien),
                imageUrl: buildImageUrl(req, f.hinhAnh),
                canteenId: f.maGianHang,
                canteenName: f.tenGianHang || '',
                categoryName: f.tenDanhMuc || 'Khác',
                description: f.moTa || '',
                rate: parseFloat(f.diemDanhGia) || 0.0,
                rating: Number(f.luotDanhGia) || 0,
                soLuongDaBan: Number(f.soLuongDaBan) || 0,
                soLuongTon: Number(f.soLuongTon) || 0,
            }));

            res.status(200).json({ success: true, data: mapped });
        } catch (error) { next(error); }
    },

    getFoodById: async (req, res, next) => {
        try {
            const food = await MonAnModel.findById(req.params.id);
            if (!food) return res.status(404).json({ success: false, message: 'Món ăn không tồn tại hoặc đã bị xóa!' });
            food.hinhAnh = buildImageUrl(req, food.hinhAnh);
            res.status(200).json({ success: true, data: food });
        } catch (error) { next(error); }
    },

    getFoodsByGianHang: async (req, res, next) => {
        try {
            const foods = await MonAnModel.findByGianHang(req.params.gianHangId);
            const mapped = foods.map(f => ({
                id: f.maMonAn,
                name: f.tenMonAn,
                price: Number(f.giaTien),
                imageUrl: buildImageUrl(req, f.hinhAnh),
                canteenId: f.maGianHang,
                categoryName: f.tenDanhMuc || '',
                description: f.moTa || '',
                rate: parseFloat(f.diemDanhGia) || 0.0,
                rating: Number(f.luotDanhGia) || 0,
                soLuongTon: Number(f.soLuongTon) || 0,
            }));
            res.status(200).json({ success: true, data: mapped });
        } catch (error) { next(error); }
    },

    // ==========================================
    // NHÓM API CHỦ QUÁN (Thêm, Sửa, Xóa)
    // ==========================================

    // Lấy menu đang bán của quán (daXoa = 0)
    getMyMenu: async (req, res, next) => {
        try {
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            if (!maGianHang) return res.status(403).json({ success: false, message: 'Bạn chưa có gian hàng!' });
            
            const foods = await MonAnModel.findByGianHang(maGianHang);
            foods.forEach(f => { f.hinhAnh = buildImageUrl(req, f.hinhAnh); });
            res.status(200).json({ success: true, data: foods });
        } catch (error) { next(error); }
    },

    // Lấy menu đã ngừng bán (daXoa = 1) — Tab "Ngừng bán"
    getDeletedMenu: async (req, res, next) => {
        try {
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            if (!maGianHang) return res.status(403).json({ success: false, message: 'Bạn chưa có gian hàng!' });
            
            const foods = await MonAnModel.findByGianHangDeleted(maGianHang);
            foods.forEach(f => { f.hinhAnh = buildImageUrl(req, f.hinhAnh); });
            res.status(200).json({ success: true, data: foods });
        } catch (error) { next(error); }
    },

    // Thêm món mới vào quán
    addFood: async (req, res, next) => {
        try {
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            if (!maGianHang) return res.status(403).json({ success: false, message: 'Bạn phải tạo gian hàng trước khi thêm món!' });

            const { tenMonAn, giaTien, hinhAnh, trangThai, moTa, maDanhMuc, soLuongTon } = req.body;
            if (!tenMonAn || !giaTien) return res.status(400).json({ success: false, message: 'Tên món và giá tiền là bắt buộc!' });

            const newFoodId = await MonAnModel.create({ maGianHang, tenMonAn, giaTien, hinhAnh, trangThai, moTa, maDanhMuc, soLuongTon });
            res.status(201).json({ success: true, message: 'Thêm món thành công!', data: { maMonAn: newFoodId } });
        } catch (error) { next(error); }
    },

    // Upload ảnh món ăn
    uploadDishImage: async (req, res, next) => {
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'Không tìm thấy file ảnh!' });
            }
            const { filename, publicPath } = await saveCroppedDishImage(req.file.buffer);
            const imageUrl = buildImageUrl(req, publicPath);
            res.status(200).json({ success: true, imageUrl, localPath: publicPath, filename });
        } catch (error) { next(error); }
    },

    // Sửa thông tin món ăn
    updateFood: async (req, res, next) => {
        try {
            const maMonAn = req.params.id;
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            
            const isUpdated = await MonAnModel.update(maMonAn, maGianHang, req.body);
            if (!isUpdated) return res.status(403).json({ success: false, message: 'Món ăn không tồn tại hoặc không thuộc quyền quản lý của bạn!' });

            res.status(200).json({ success: true, message: 'Cập nhật món ăn thành công!' });
        } catch (error) { next(error); }
    },

    // Xóa mềm món ăn (chuyển sang tab Ngừng bán)
    deleteFood: async (req, res, next) => {
        try {
            const maMonAn = req.params.id;
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            
            const isDeleted = await MonAnModel.softDelete(maMonAn, maGianHang);
            if (!isDeleted) return res.status(403).json({ success: false, message: 'Không thể xóa! Món ăn không tồn tại hoặc không thuộc gian hàng của bạn.' });

            res.status(200).json({ success: true, message: 'Đã chuyển món ăn sang Ngừng bán!' });
        } catch (error) { next(error); }
    },

    // Khôi phục món ăn đã ngừng bán
    restoreFood: async (req, res, next) => {
        try {
            const maMonAn = req.params.id;
            const maGianHang = await MonAnModel.getMaGianHangByTaiKhoan(req.user.maTaiKhoan);
            
            const stock = req.body.soLuongTon ? Number(req.body.soLuongTon) : 0;
            const isRestored = await MonAnModel.restore(maMonAn, maGianHang, stock);
            if (!isRestored) return res.status(403).json({ success: false, message: 'Không thể khôi phục! Món ăn không tồn tại hoặc không thuộc gian hàng của bạn.' });

            res.status(200).json({ success: true, message: 'Đã khôi phục món ăn thành công!' });
        } catch (error) { next(error); }
    }
};

module.exports = MonAnController;