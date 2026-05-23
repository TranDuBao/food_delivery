// lib/view/customer/group/group_members_sheet.dart
// Bottom sheet danh sách thành viên nhóm

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'group_model.dart';

// Phải import _colorForSender từ chat_tab nếu muốn dùng chung,
// ở đây tự tính lại cho gọn.
Color _colorFor(String id) {
  const colors = [
    Color(0xFF6C63FF), Color(0xFF2ECC71), Color(0xFFE74C3C),
    Color(0xFF3498DB), Color(0xFFE67E22), Color(0xFF9B59B6),
    Color(0xFF1ABC9C), Color(0xFFE91E63),
  ];
  final hash = id.codeUnits.fold(0, (a, b) => a + b);
  return colors[hash % colors.length];
}

class GroupMembersSheet extends StatelessWidget {
  final GroupModel group;
  final String myId;

  const GroupMembersSheet({
    super.key,
    required this.group,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    // Chủ nhóm + thành viên
    final ownerEntry = _OwnerEntry(ownerId: group.ownerId, myId: myId);
    final memberList = group.members.where((m) => m.userId != group.ownerId).toList();
    final total = (group.ownerId.isNotEmpty ? 1 : 0) + memberList.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Expanded(
              child: Text('Thành viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$total người',
                  style: TextStyle(
                      color: TColor.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Chủ nhóm
              if (group.ownerId.isNotEmpty)
                _MemberTile(
                  userId: group.ownerId,
                  name: ownerEntry.name,
                  isMe: group.ownerId == myId,
                  badge: '👑 Chủ nhóm',
                  badgeColor: const Color(0xFFFF6B35),
                ),
              // Thành viên
              ...memberList.map((m) => _MemberTile(
                    userId: m.userId,
                    name: m.name,
                    isMe: m.userId == myId,
                    badge: m.isAdmin ? '⚙️ Admin' : null,
                    badgeColor: TColor.primary,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Helper để lấy tên chủ nhóm ──────────────────────────────────────────────
class _OwnerEntry {
  final String ownerId;
  final String myId;
  const _OwnerEntry({required this.ownerId, required this.myId});
  String get name => ownerId == myId ? 'Bạn (chủ nhóm)' : 'Chủ nhóm';
}

// ─── Member tile ──────────────────────────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  final String userId;
  final String name;
  final bool isMe;
  final String? badge;
  final Color? badgeColor;

  const _MemberTile({
    required this.userId,
    required this.name,
    required this.isMe,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(userId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMe ? TColor.primary.withValues(alpha: 0.06) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? TColor.primary.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.18),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isMe ? '$name (Bạn)' : name,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isMe ? TColor.primary : Colors.black87),
          ),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? TColor.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: TextStyle(
                      color: badgeColor ?? TColor.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
        ])),
        if (isMe)
          Icon(Icons.person_rounded, color: TColor.primary, size: 18),
      ]),
    );
  }
}
