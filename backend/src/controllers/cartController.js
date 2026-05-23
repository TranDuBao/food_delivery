// controllers/cartController.js
const CartModel = require('../models/cartModel');
const MonAnModel = require('../models/dishesModel');

const CartController = {
    // 1. Xem giỏ hàng & Tính tổng tiền
    getCart: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const cart = await CartModel.getCart(maTaiKhoan);
            
            // Prepend host to hinhAnh for all items in the cart
            cart.forEach(item => {
                if (item.hinhAnh && !item.hinhAnh.startsWith('http')) {
                    item.hinhAnh = `${req.protocol}://${req.get('host')}${item.hinhAnh}`;
                }
            });
            
            const tongTien = cart.reduce((sum, item) => sum + (Number(item.giaTien) * item.soLuong), 0);

            res.status(200).json({ success: true, data: cart, tongTien: tongTien });
        } catch (error) { next(error); }
    },

    // 2. Thêm món vào giỏ (KHÔNG GIỚI HẠN QUÁN)
    addToCart: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { maMonAn, soLuong } = req.body;
            const soLuongSafe = soLuong ? Number(soLuong) : 1;

            // Kiểm tra món ăn có tồn tại không
            const food = await MonAnModel.findById(maMonAn);
            if (!food) {
                return res.status(404).json({ success: false, message: 'Món ăn không tồn tại hoặc đã ngừng bán!' });
            }

            // Mở khóa: Bỏ đoạn check currentStoreId. Khách muốn thêm món của tiệm nào cũng duyệt!
            await CartModel.addToCart(maTaiKhoan, maMonAn, soLuongSafe);
            
            res.status(200).json({ success: true, message: 'Đã thêm món vào giỏ hàng!' });

        } catch (error) { next(error); }
    },

    // 3. Cập nhật số lượng
    updateQuantity: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { maMonAn, soLuong } = req.body;

            if (soLuong <= 0) {
                await CartModel.removeItem(maTaiKhoan, maMonAn);
                return res.status(200).json({ success: true, message: 'Đã xóa món ăn khỏi giỏ!' });
            }

            await CartModel.updateQuantity(maTaiKhoan, maMonAn, soLuong);
            res.status(200).json({ success: true, message: 'Đã cập nhật số lượng!' });
        } catch (error) { next(error); }
    },

    // 4. Xóa cứng 1 món
    removeItem: async (req, res, next) => {
        try {
            const maMonAn = req.params.id;
            await CartModel.removeItem(req.user.maTaiKhoan, maMonAn);
            res.status(200).json({ success: true, message: 'Đã xóa khỏi giỏ!' });
        } catch (error) { next(error); }
    },

    // 5. Xóa sạch giỏ
    clearCart: async (req, res, next) => {
        try {
            await CartModel.clearCart(req.user.maTaiKhoan);
            res.status(200).json({ success: true, message: 'Giỏ hàng đã được làm trống!' });
        } catch (error) { next(error); }
    }
};

module.exports = CartController;