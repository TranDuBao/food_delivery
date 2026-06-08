const GroupModel = require('../models/groupModel');
const GroupOrderModel = require('../models/groupOrderModel');

const GroupController = {
  createGroup: async (req, res, next) => {
    try {
      const { name } = req.body;
      const creatorId = req.user.maTaiKhoan || req.user.id; // From verifyToken middleware
      if (!name) return res.status(400).json({ success: false, message: 'Tên nhóm là bắt buộc' });

      const group = await GroupModel.createGroup(name, creatorId);
      res.status(201).json({ success: true, data: group });
    } catch (error) {
      next(error);
    }
  },

  getGroups: async (req, res, next) => {
    try {
      const userId = req.user.maTaiKhoan || req.user.id;
      const groups = await GroupModel.getGroupsByUserId(userId);
      res.status(200).json({ success: true, data: groups });
    } catch (error) {
      next(error);
    }
  },

  joinGroup: async (req, res, next) => {
    try {
      const { groupId } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId) return res.status(400).json({ success: false, message: 'groupId là bắt buộc' });
      const result = await GroupModel.joinGroup(groupId, userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  leaveGroup: async (req, res, next) => {
    try {
      const { groupId } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId) return res.status(400).json({ success: false, message: 'groupId là bắt buộc' });
      const result = await GroupModel.leaveGroup(groupId, userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  removeMember: async (req, res, next) => {
    try {
      const { groupId, targetUserId } = req.body;
      const ownerId = req.user.maTaiKhoan || req.user.id;
      if (!groupId || !targetUserId) return res.status(400).json({ success: false, message: 'groupId và targetUserId là bắt buộc' });
      const result = await GroupModel.removeMember(groupId, ownerId, targetUserId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  disbandGroup: async (req, res, next) => {
    try {
      const { groupId } = req.body;
      const ownerId = req.user.maTaiKhoan || req.user.id;
      if (!groupId) return res.status(400).json({ success: false, message: 'groupId là bắt buộc' });
      const result = await GroupModel.disbandGroup(groupId, ownerId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  // ── Group Cart ─────────────────────────────────────────────────────────────

  getGroupCart: async (req, res, next) => {
    try {
      const { groupId } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId) return res.status(400).json({ success: false, message: 'groupId là bắt buộc' });

      // Kiểm tra thành viên
      const isMember = await GroupOrderModel.isMember(groupId, userId);
      console.log(`[GroupCart] userId=${userId}, groupId=${groupId}, isMember=${isMember}`);
      if (!isMember) return res.status(403).json({ success: false, message: 'Bạn không phải thành viên nhóm này' });

      const cart = await GroupOrderModel.getGroupCart(groupId);
      console.log(`[GroupCart] cart count=${cart.length}`);
      // Tính discount
      const uniqueUsers = [...new Set(cart.map(i => i.maTaiKhoan))].length;
      const discount = GroupOrderModel.calcDiscount(uniqueUsers);

      res.status(200).json({ success: true, data: cart, discount });
    } catch (error) {
      console.error('[GroupCart] error:', error);
      next(error);
    }
  },

  addToGroupCart: async (req, res, next) => {
    try {
      const { groupId, maMonAn, soLuong = 1, ghiChu } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId || !maMonAn) return res.status(400).json({ success: false, message: 'groupId và maMonAn là bắt buộc' });

      const isMember = await GroupOrderModel.isMember(groupId, userId);
      if (!isMember) return res.status(403).json({ success: false, message: 'Bạn không phải thành viên nhóm này' });

      const result = await GroupOrderModel.addToGroupCart(groupId, userId, maMonAn, soLuong, ghiChu);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  updateGroupCartItem: async (req, res, next) => {
    try {
      const { maGioHangNhom, soLuong } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!maGioHangNhom) return res.status(400).json({ success: false, message: 'maGioHangNhom là bắt buộc' });

      const result = await GroupOrderModel.updateGroupCartItem(maGioHangNhom, userId, soLuong ?? 0);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  removeGroupCartItem: async (req, res, next) => {
    try {
      const { maGioHangNhom } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!maGioHangNhom) return res.status(400).json({ success: false, message: 'maGioHangNhom là bắt buộc' });

      const result = await GroupOrderModel.removeGroupCartItem(maGioHangNhom, userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  },

  clearGroupCart: async (req, res, next) => {
    try {
      const { groupId } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId) return res.status(400).json({ success: false, message: 'groupId là bắt buộc' });

      // Chỉ xoá món của chính mình (không phải toàn bộ nhóm)
      await require('../config/db').query(
        `DELETE FROM giohang_nhom WHERE maNhom = ? AND maTaiKhoan = ?`,
        [groupId, userId]
      );
      res.status(200).json({ success: true });
    } catch (error) {
      next(error);
    }
  },

  groupCheckout: async (req, res, next) => {
    try {
      const { groupId, maToaNha, maPhong, phuongThucThanhToan } = req.body;
      const userId = req.user.maTaiKhoan || req.user.id;
      if (!groupId || !maToaNha || !maPhong) {
        return res.status(400).json({ success: false, message: 'groupId, maToaNha và maPhong là bắt buộc' });
      }

      // Kiểm tra nhóm tồn tại
      const groups = await require('../config/db').query(
        `SELECT maNhom FROM nhom WHERE maNhom = ? AND trangThai = 1`, [groupId]
      );
      if (groups.length === 0) return res.status(404).json({ success: false, message: 'Nhóm không tồn tại' });

      // Xác định người tạo đơn = người thêm món ĐẦU TIÊN vào giỏ hàng nhóm
      const firstItems = await require('../config/db').query(
        `SELECT maTaiKhoan FROM giohang_nhom WHERE maNhom = ? ORDER BY thoiGianThem ASC LIMIT 1`,
        [groupId]
      );

      if (firstItems.length === 0) {
        return res.status(400).json({ success: false, message: 'Giỏ hàng nhóm đang trống' });
      }

      const creatorId = firstItems[0].maTaiKhoan;
      if (String(creatorId) !== String(userId)) {
        return res.status(403).json({
          success: false,
          message: 'Chỉ người tạo đơn (người thêm món đầu tiên) mới được đặt hàng cho nhóm'
        });
      }

      const orders = await GroupOrderModel.groupCheckout({
        maNhom: groupId,
        maToaNha,
        maPhong,
        phuongThucThanhToan: phuongThucThanhToan || 'COD',
      });

      res.status(201).json({ success: true, data: { orders, message: `Đã tạo ${orders.length} đơn hàng thành công` } });
    } catch (error) {
      next(error);
    }
  },

};

module.exports = GroupController;
