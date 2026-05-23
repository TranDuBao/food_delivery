// controllers/canteenController.js
const GianHangModel = require('../models/canteenModel');
const { saveCroppedDishImage } = require('../config/upload');

const buildUrl = (req, p) => (!p ? '' : p.startsWith('http') ? p : `${req.protocol}://${req.get('host')}${p}`);

const GianHangController = {
    getAllStores: async (req, res, next) => {
        try {
            const stores = await GianHangModel.getAll();

            // Lấy rating và top dishes song song cho tất cả gian hàng
            const enriched = await Promise.all(stores.map(async (s) => {
                const url = buildUrl(req, s.banner);
                const [ratingInfo, topDishes] = await Promise.all([
                    GianHangModel.getStoreRating(s.maGianHang),
                    GianHangModel.getTopDishes(s.maGianHang, 3),
                ]);

                return {
                    id: s.maGianHang,
                    name: s.tenGianHang,
                    logoUrl: url,
                    bannerUrl: url,
                    location: s.moTa,
                    openHours: s.gioMoCua,
                    totalDishes: '10',
                    // Rating trung bình từ đánh giá khách hàng
                    avgRating: ratingInfo.avgRating ? parseFloat(ratingInfo.avgRating) : null,
                    totalReviews: parseInt(ratingInfo.totalReviews) || 0,
                    // Top 3 món nổi bật
                    topDishes: topDishes.map(d => ({
                        id: d.maMonAn,
                        name: d.tenMonAn,
                        imageUrl: buildUrl(req, d.hinhAnh),
                        price: parseFloat(d.giaTien) || 0,
                        rating: parseFloat(d.diemDanhGia) || 0,
                        reviewCount: parseInt(d.luotDanhGia) || 0,
                        soldCount: parseInt(d.soLuongDaBan) || 0,
                    })),
                };
            }));

            res.status(200).json({ success: true, data: enriched });
        } catch (error) {
            next(error);
        }
    },

    getStoreById: async (req, res, next) => {
        try {
            const { id } = req.params; 
            const store = await GianHangModel.findById(id);
            if (!store) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng này!' });
            }
            store.banner = buildUrl(req, store.banner);
            res.status(200).json({ success: true, data: store });
        } catch (error) {
            next(error);
        }
    },

    getMyStore: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan; 
            let store = await GianHangModel.findByOwnerId(maTaiKhoan);
            if (!store) {
                return res.status(404).json({ success: false, message: 'Bạn chưa cấu hình gian hàng nào!' });
            }
            store.banner = buildUrl(req, store.banner);
            res.status(200).json({ success: true, data: store });
        } catch (error) {
            next(error);
        }
    },

    // Upload banner gian hàng
    uploadBanner: async (req, res, next) => {
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'Không tìm thấy file ảnh!' });
            }
            const { filename, publicPath } = await saveCroppedDishImage(req.file.buffer);
            const imageUrl = buildUrl(req, publicPath);
            res.status(200).json({ success: true, imageUrl, localPath: publicPath, filename });
        } catch (error) {
            next(error);
        }
    },

    updateMyStore: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { tenGianHang, moTa, banner, soDienThoai, gioMoCua } = req.body;

            let store = await GianHangModel.findByOwnerId(maTaiKhoan);
            
            if (!store) {
                if (!tenGianHang) {
                    return res.status(400).json({ success: false, message: 'Tên gian hàng không được để trống khi tạo mới!' });
                }
                const newStoreId = await GianHangModel.create(maTaiKhoan, tenGianHang);
                store = { maGianHang: newStoreId };
            }

            const updateData = {
                tenGianHang: tenGianHang || store.tenGianHang,
                moTa: moTa || store.moTa,
                banner: banner || store.banner,
                soDienThoai: soDienThoai || store.soDienThoai,
                gioMoCua: gioMoCua || store.gioMoCua
            };

            await GianHangModel.update(store.maGianHang, updateData);

            res.status(200).json({
                success: true,
                message: 'Cập nhật thông tin gian hàng thành công!',
                data: updateData
            });
        } catch (error) {
            next(error);
        }
    },

    // LẤY DANH SÁCH MÓN ĐANG CHỜ CỦA QUÁN
    getPendingOrders: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const store = await GianHangModel.findByOwnerId(maTaiKhoan);
            if (!store) {
                 return res.status(403).json({ success: false, message: 'Bạn chưa tạo gian hàng' });
            }
            const pendingOrders = await GianHangModel.getPendingOrdersForStore(store.maGianHang);
            res.status(200).json({ success: true, data: pendingOrders });
        } catch (error) {
            next(error);
        }
    },

    // ĐÁNH DẤU MỘT MÓN TRONG ĐƠN LÀ ĐÃ XONG
    markDishDone: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { itemId } = req.params; // maChiTietDonHang

            const store = await GianHangModel.findByOwnerId(maTaiKhoan);
            if (!store) return res.status(403).json({ success: false, message: 'Cần cấu hình gian hàng trước' });

            const result = await GianHangModel.updateDishStatus(itemId, store.maGianHang);
            if (!result) {
                 return res.status(404).json({ success: false, message: 'Không tìm thấy món hoặc món không thuộc quán của bạn!' });
            }

            // Kiểm tra ngầm toàn nhóm để chuyển cho Shipper
            const isGroupReady = await GianHangModel.checkAndUpdateGroupStatusIfDone(result.maNhomGiaoHang);

            res.status(200).json({ 
                 success: true, 
                 message: 'Đã báo xong món ăn!',
                 isGroupReady: isGroupReady // Trả về thông báo để FE UI biết nếu nhóm đã sẵn sàng cho shipper
            });
        } catch (error) {
             next(error);
        }
    }
};

module.exports = GianHangController;