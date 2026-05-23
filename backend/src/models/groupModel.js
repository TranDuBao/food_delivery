const db = require('../config/db');
const crypto = require('crypto');

const GroupModel = {
  createGroup: async (name, creatorId) => {
    const groupId = crypto.randomUUID();
    const referralCode = 'G' + Math.random().toString(36).substring(2, 8).toUpperCase();

    // Create group
    await db.query(
      `INSERT INTO nhom (maNhom, tenNhom, maMoi, maNguoiTao) VALUES (?, ?, ?, ?)`,
      [groupId, name, referralCode, creatorId]
    );

    // Add creator as admin
    await db.query(
      `INSERT INTO thanhvien_nhom (maNhom, maTaiKhoan, vaiTro) VALUES (?, ?, 'admin')`,
      [groupId, creatorId]
    );

    // Create wallet
    await db.query(
      `INSERT INTO vi_nhom (maNhom, soDu, maQR) VALUES (?, 0, ?)`,
      [groupId, `QR-${referralCode}`]
    );

    return {
      id: groupId,
      name,
      referralCode,
      ownerId: creatorId,
      createdAt: new Date(),
      members: [{
        userId: creatorId,
        name: 'Admin', // Temporary, frontend will refresh
        isAdmin: true
      }],
      wallet: {
        groupId: groupId,
        balance: 0,
        qrCode: `QR-${referralCode}`
      }
    };
  },

  getGroupsByUserId: async (userId) => {
    const groups = await db.query(
      `SELECT n.maNhom AS id, n.tenNhom AS name, n.anhDaiDien as avatarUrl, n.maMoi as referralCode, n.maNguoiTao as ownerId, n.thoiGianTao as createdAt, v.soDu AS balance, v.maQR as qrCode
       FROM nhom n
       JOIN thanhvien_nhom tv ON n.maNhom = tv.maNhom
       LEFT JOIN vi_nhom v ON n.maNhom = v.maNhom
       WHERE tv.maTaiKhoan = ? AND n.trangThai = 1
       ORDER BY n.thoiGianTao DESC`,
      [userId]
    );

    // Fetch members for each group
    for (let group of groups) {
      const members = await db.query(
        `SELECT tv.maTaiKhoan as userId, t.hoTen as name, t.anhDaiDien as avatarUrl, tv.vaiTro 
         FROM thanhvien_nhom tv
         JOIN taikhoan t ON tv.maTaiKhoan = t.maTaiKhoan
         WHERE tv.maNhom = ?`,
        [group.id]
      );
      group.members = members.map(m => ({
        userId: m.userId.toString(),
        name: m.name,
        avatarUrl: m.avatarUrl,
        isAdmin: m.vaiTro === 'admin'
      }));

      group.wallet = {
        groupId: group.id,
        balance: parseFloat(group.balance || 0),
        qrCode: group.qrCode || ''
      };

      // Đảm bảo ownerId cũng là string để đồng bộ frontend
      group.ownerId = group.ownerId.toString();
    }
    return groups;
  },

  joinGroup: async (groupId, userId) => {
    // Kiểm tra group tồn tại
    const groups = await db.query(
      `SELECT maNhom, maNguoiTao as ownerId FROM nhom WHERE maNhom = ? AND trangThai = 1`,
      [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');

    // Kiểm tra đã là thành viên chưa
    const existing = await db.query(
      `SELECT maThanhVienNhom FROM thanhvien_nhom WHERE maNhom = ? AND maTaiKhoan = ?`,
      [groupId, userId]
    );
    if (existing.length > 0) return { alreadyMember: true };

    // Thêm vào nhóm
    await db.query(
      `INSERT INTO thanhvien_nhom (maNhom, maTaiKhoan, vaiTro) VALUES (?, ?, 'member')`,
      [groupId, userId]
    );
    return { alreadyMember: false };
  },

  leaveGroup: async (groupId, userId) => {
    const groups = await db.query(
      `SELECT maNguoiTao FROM nhom WHERE maNhom = ? AND trangThai = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].maNguoiTao == userId) throw new Error('Nhóm trưởng không thể rời nhóm, hãy giải tán nhóm');
    await db.query(`DELETE FROM thanhvien_nhom WHERE maNhom = ? AND maTaiKhoan = ?`, [groupId, userId]);
    return { success: true };
  },

  removeMember: async (groupId, ownerId, targetUserId) => {
    const groups = await db.query(
      `SELECT maNguoiTao FROM nhom WHERE maNhom = ? AND trangThai = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].maNguoiTao != ownerId) throw new Error('Không có quyền xóa thành viên');
    if (targetUserId == ownerId) throw new Error('Không thể xóa chính mình');
    await db.query(`DELETE FROM thanhvien_nhom WHERE maNhom = ? AND maTaiKhoan = ?`, [groupId, targetUserId]);
    return { success: true };
  },

  disbandGroup: async (groupId, ownerId) => {
    const groups = await db.query(
      `SELECT maNguoiTao FROM nhom WHERE maNhom = ? AND trangThai = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].maNguoiTao != ownerId) throw new Error('Chỉ nhóm trưởng mới được giải tán nhóm');
    await db.query(`UPDATE nhom SET trangThai = 0 WHERE maNhom = ?`, [groupId]);
    return { success: true };
  }
};

module.exports = GroupModel;
