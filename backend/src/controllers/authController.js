// controllers/auth.controller.js
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const AuthModel = require('../models/authModel');

// Secret key cho JWT (Nên đưa vào file .env)
const JWT_SECRET = process.env.JWT_SECRET || 'BiMatCuaDoAnNam4_KhongDuocDeLo';

const AuthController = {
    // 1. ĐĂNG KÝ
    register: async (req, res, next) => {
        try {
            const { tenDangNhap, matKhau, hoTen, email, soDienThoai } = req.body;

            // Kiểm tra trùng lặp
            const userExists = await AuthModel.findByUsername(tenDangNhap);
            if (userExists) {
                return res.status(400).json({ success: false, message: 'Tên đăng nhập đã tồn tại!' });
            }

            // Mã hóa mật khẩu (Salt round = 10)
            const matKhauHash = await bcrypt.hash(matKhau, 10);

            // Lưu vào DB
            const newUserId = await AuthModel.createAccount({
                tenDangNhap, matKhauHash, hoTen, email, soDienThoai
            });

            res.status(201).json({
                success: true,
                message: 'Đăng ký tài khoản thành công!',
                data: { maTaiKhoan: newUserId }
            });
        } catch (error) {
            next(error); // Đẩy lỗi qua ErrorHandler
        }
    },

    // 2. ĐĂNG NHẬP
    login: async (req, res, next) => {
        try {
            const { tenDangNhap, matKhau } = req.body;

            // Tìm user
            const user = await AuthModel.findByUsername(tenDangNhap);
            if (!user) {
                return res.status(401).json({ success: false, message: 'Tài khoản không tồn tại!' });
            }

            // Check trạng thái khóa
            if (user.trangThai === 0) {
                // Tự động mở khóa nếu hết hạn
                if (!user.khoaVinhVien && user.thoiGianKhoa) {
                    const now = new Date();
                    if (new Date(user.thoiGianKhoa) <= now) {
                        const { query } = require('../config/db');
                        await query(
                            `UPDATE taikhoan SET trangThai=1, thoiGianKhoa=NULL WHERE maTaiKhoan=?`,
                            [user.maTaiKhoan]
                        ).catch(() => {});
                        // Cho phép đăng nhập bình thường
                        user.trangThai = 1;
                    }
                }
                if (user.trangThai === 0) {
                    let msg = 'Tài khoản của bạn đã bị khóa!';
                    if (user.khoaVinhVien) {
                        msg = 'Tài khoản của bạn đã bị khóa vĩnh viễn. Vui lòng liên hệ quản trị viên.';
                    } else if (user.thoiGianKhoa) {
                        const diff = new Date(user.thoiGianKhoa) - new Date();
                        const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
                        msg = `Tài khoản của bạn đang bị khóa. Còn ${days} ngày để mở khóa.`;
                    }
                    return res.status(403).json({ success: false, message: msg });
                }
            }

            // So sánh mật khẩu
            const isMatch = await bcrypt.compare(matKhau, user.matKhau);
            if (!isMatch) {
                return res.status(401).json({ success: false, message: 'Mật khẩu không chính xác!' });
            }

            // Tạo Token
            const payload = {
                maTaiKhoan: user.maTaiKhoan,
                maVaiTro: user.maVaiTro
            };
            const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' }); // Hạn 7 ngày

            // Xóa field matKhau trước khi trả về client để bảo mật
            delete user.matKhau;

            res.status(200).json({
                success: true,
                message: 'Đăng nhập thành công!',
                token: token,
                user: user
            });
        } catch (error) {
            next(error);
        }
    },

    // 3. QUÊN MẬT KHẨU (Demo cấp lại mật khẩu mới)
    forgotPassword: async (req, res, next) => {
        try {
            const { tenDangNhap, soDienThoai } = req.body;

            const user = await AuthModel.findByUsername(tenDangNhap);
            // Xác thực thêm số điện thoại để đảm bảo đúng chủ tài khoản
            if (!user || user.soDienThoai !== soDienThoai) {
                return res.status(404).json({ success: false, message: 'Thông tin xác thực không khớp!' });
            }

            // Tạo mật khẩu ngẫu nhiên mới (Trong thực tế nên gửi mã OTP qua SMS/Email)
            const newPassword = Math.random().toString(36).slice(-8);
            const newHash = await bcrypt.hash(newPassword, 10);

            await AuthModel.updatePassword(user.maTaiKhoan, newHash);

            res.status(200).json({
                success: true,
                message: 'Đã reset mật khẩu thành công!',
                newPassword: newPassword // (Chỉ dùng cho demo đồ án, thực tế không trả thẳng về API)
            });
        } catch (error) {
            next(error);
        }
    },

    // 4. ĐĂNG NHẬP BẰNG MẠNG XÃ HỘI (Google / Facebook)
    socialLogin: async (req, res, next) => {
        try {
            const { email, hoTen, provider, providerId, anhDaiDien } = req.body;

            if (!email || !provider || !providerId) {
                return res.status(400).json({
                    success: false,
                    message: 'Thiếu thông tin đăng nhập mạng xã hội!'
                });
            }

            // Tìm hoặc tạo tài khoản
            const user = await AuthModel.findOrCreateSocialAccount({
                email, hoTen: hoTen || email.split('@')[0], provider, providerId, anhDaiDien
            });

            if (!user) {
                return res.status(500).json({ success: false, message: 'Không thể xử lý tài khoản!' });
            }

            if (user.trangThai === 0) {
                return res.status(403).json({ success: false, message: 'Tài khoản đã bị khóa!' });
            }

            // Tạo JWT
            const payload = { maTaiKhoan: user.maTaiKhoan, maVaiTro: user.maVaiTro };
            const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });

            delete user.matKhau;

            res.status(200).json({
                success: true,
                message: 'Đăng nhập thành công!',
                token,
                user
            });
        } catch (error) {
            next(error);
        }
    },

    // 5. ĐĂNG XUẤT
    logout: async (req, res, next) => {
        try {
            res.status(200).json({
                success: true,
                message: 'Đăng xuất thành công! Client vui lòng xóa token.'
            });
        } catch (error) {
            next(error);
        }
    }
};

module.exports = AuthController;