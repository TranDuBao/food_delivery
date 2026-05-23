const GroupModel = require('../models/groupModel');

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
  }
};

module.exports = GroupController;
