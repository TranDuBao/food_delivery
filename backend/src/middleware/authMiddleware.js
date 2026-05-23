// middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'BiMatCuaDoAnNam4_KhongDuocDeLo';

const verifyToken = (req, res, next) => {
    // Lấy token từ header: "Authorization: Bearer <token>"
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'Không tìm thấy token truy cập!' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded; // Gắn thông tin { maTaiKhoan, maVaiTro } vào request
        next(); // Cho phép đi tiếp vào Controller
    } catch (error) {
        return res.status(403).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn!' });
    }
};

// Hàm check phân quyền (Role-based)
const authorizeRole = (allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.maVaiTro)) {
            return res.status(403).json({ success: false, message: 'Bạn không có quyền thực hiện hành động này!' });
        }
        next();
    };
};

module.exports = { verifyToken, authorizeRole };