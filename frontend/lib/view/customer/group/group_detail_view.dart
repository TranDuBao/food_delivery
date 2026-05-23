import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'chat_service.dart';
import 'group_chat_tab.dart';
import 'group_members_sheet.dart';
import 'group_model.dart';
import 'group_requests_tab.dart';
import 'group_service.dart';
import 'group_wallet_view.dart';

class GroupDetailView extends StatefulWidget {
  final GroupModel group;
  const GroupDetailView({super.key, required this.group});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  late GroupModel _group;
  final List<GroupMessage> _messages = [];
  bool _isLoadingChat = true;

  // Lưu sẵn khi initState — không dùng getter tự tính vì có thể thay đổi giữa các await
  String _myId = '';
  String _myName = 'Bạn';

  static String _resolveId(Map<String, dynamic> p) =>
      p['maTaiKhoan']?.toString() ??
      p['id']?.toString() ??
      p['_id']?.toString() ?? '';

  static String _resolveName(Map<String, dynamic> p) =>
      p['hoTen']?.toString() ??
      p['name']?.toString() ??
      p['fullName']?.toString() ?? 'Bạn';

  // Chủ nhóm
  bool get _isAdmin {
    if (_group.ownerId == _myId) return true;
    if (_group.members.isEmpty) return false;
    return _group.members.any((m) => m.userId == _myId && m.isAdmin);
  }

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    // Lưu ID/tên ngay khi init — tránh thay đổi giữa các async gaps
    final p = Map<String, dynamic>.from(ServiceCall.userPayload);
    _myId = _resolveId(p);
    _myName = _resolveName(p);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    var saved = await ChatService.instance.loadMessages(_group.id);

    // Migration: tin nhắn cũ có senderId = '' (vì _myId lúc đó chưa đúng)
    // → gán lại đúng myId để hiển thị đúng bên phải
    if (saved.any((m) => m.senderId.isEmpty) && _myId.isNotEmpty) {
      saved = saved.map((m) {
        if (m.senderId.isEmpty) {
          return GroupMessage(
            id: m.id,
            senderId: _myId,
            senderName: _myName,
            text: m.text,
            imageUrl: m.imageUrl,
            timestamp: m.timestamp,
            seenBy: List<String>.from(m.seenBy),
          );
        }
        return m;
      }).toList();
      // Lưu lại đã fix
      await ChatService.instance.saveMessages(_group.id, saved);
    }

    // Đánh dấu toàn bộ là đã đọc
    saved = await ChatService.instance.markSeen(_group.id, _myId, saved);
    if (mounted) {
      setState(() {
        _messages.addAll(saved);
        _isLoadingChat = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> _sendText(String text) async {
    final msg = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myId, senderName: _myName,
      text: text, timestamp: DateTime.now(),
      seenBy: [_myId], // mình tự cà đã thấy
    );
    setState(() => _messages.add(msg));
    await ChatService.instance.appendMessage(_group.id, msg);
  }

  // ── Invite member ─────────────────────────────────────────────────────────
  Future<void> _inviteMember() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mời thành viên', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Mã nhóm: ${_group.referralCode}',
              style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800,
                  fontSize: 20, letterSpacing: 3)),
          const SizedBox(height: 16),
          TextField(controller: ctrl,
            decoration: InputDecoration(hintText: 'Email hoặc số điện thoại...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColor.primary, width: 1.5)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              await GroupService.instance.inviteMember(_group.id, email);
              AppNotification.show(context,
                  message: 'Đã gửi lời mời đến $email', type: NotifType.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Gửi mời', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Edit group name ───────────────────────────────────────────────────────
  Future<void> _editGroupName() async {
    final ctrl = TextEditingController(text: _group.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi tên nhóm', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, autofocus: true,
          decoration: InputDecoration(hintText: 'Tên nhóm...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.primary, width: 1.5)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _group = _group.copyWith(name: result));
      await GroupService.instance.updateGroup(_group);
    }
  }

  // ── Leave group (member) ──────────────────────────────────────
  Future<void> _leaveGroup() async {
    final ok = await AppNotification.confirm(context,
        title: 'Rời nhóm',
        message: 'Bạn có chắc muốn rời nhóm "${_group.name}"?',
        confirmText: 'Rời nhóm', cancelText: 'Huỷ');
    if (ok != true || !mounted) return;
    try {
      await ServiceCall.fetchPost(SVKey.svGroupLeave, body: {
        'groupId': _group.id,
      }, isToken: true);
      // Xóa khỏi local cache ngay lập tức
      await GroupService.instance.deleteGroup(_group.id);
      if (mounted) {
        AppNotification.show(context,
            message: 'Đã rời nhóm "${_group.name}"', type: NotifType.info);
        Navigator.pop(context, true); // true = cần reload
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context,
            message: e.toString(), type: NotifType.error);
      }
    }
  }

  // ── Disband group (owner) ───────────────────────────────────
  Future<void> _disbandGroup() async {
    final ok = await AppNotification.confirm(context,
        title: 'Giải tán nhóm',
        message: 'Bạn có chắc muốn giải tán nhóm "${_group.name}"?',
        confirmText: 'Giải tán', cancelText: 'Huỷ');
    if (ok != true || !mounted) return;
    try {
      await ServiceCall.fetchPost(SVKey.svGroupDisband, body: {
        'groupId': _group.id,
      }, isToken: true);
      await GroupService.instance.deleteGroup(_group.id);
      if (mounted) {
        AppNotification.show(context,
            message: 'Đã giải tán nhóm "${_group.name}"', type: NotifType.info);
        Navigator.pop(context, true); // true = cần reload
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context,
            message: e.toString(), type: NotifType.error);
      }
    }
  }

  // ── Remove member (owner only) ───────────────────────────────────
  Future<void> _showRemoveMemberDialog() async {
    final otherMembers = _group.members.where((m) => m.userId != _myId).toList();
    if (otherMembers.isEmpty) {
      AppNotification.show(context,
          message: 'Nhóm chưa có thành viên nào khác', type: NotifType.info);
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xóa thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Chọn thành viên muốn xóa khỏi nhóm',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            ...otherMembers.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await AppNotification.confirm(context,
                      title: 'Xóa thành viên',
                      message: 'Xóa "${m.name}" khỏi nhóm?',
                      confirmText: 'Xóa', cancelText: 'Huỷ');
                  if (ok != true || !mounted) return;
                  try {
                    await ServiceCall.fetchPost(SVKey.svGroupRemoveMember, body: {
                      'groupId': _group.id,
                      'targetUserId': m.userId,
                    }, isToken: true);
                    final newMembers = _group.members.where((x) => x.userId != m.userId).toList();
                    setState(() => _group = _group.copyWith(members: newMembers));
                    await GroupService.instance.updateGroup(_group);
                    if (mounted) {
                      AppNotification.show(context,
                          message: 'Đã xóa ${m.name} khỏi nhóm', type: NotifType.success);
                    }
                  } catch (e) {
                    if (mounted) {
                      AppNotification.show(context, message: e.toString(), type: NotifType.error);
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: _editGroupName,
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TColor.primary.withValues(alpha: 0.12),
              backgroundImage: _group.avatarUrl != null ? NetworkImage(_group.avatarUrl!) : null,
              child: _group.avatarUrl == null
                  ? Text(_group.name[0].toUpperCase(),
                      style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_group.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            Text('${_group.members.length + (_group.ownerId.isNotEmpty && !_group.members.any((m) => m.userId == _group.ownerId) ? 1 : 0)} thành viên',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
          ]),
        ),
        actions: [
          // Nút xem thành viên
          IconButton(
            icon: const Icon(Icons.group_rounded),
            color: Colors.grey.shade600,
            tooltip: 'Thành viên',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GroupMembersSheet(
                  group: _group, myId: _myId),
            ),
          ),
          // Nút yêu cầu tham gia (chỉ admin thấy khi có yêu cầu)
          if (_isAdmin && _group.pendingRequests.isNotEmpty)
            Stack(alignment: Alignment.topRight, children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                color: TColor.primary,
                tooltip: 'Yêu cầu tham gia',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GroupRequestsSheet(
                    group: _group,
                    onChanged: () => setState(() {
                      final updated = GroupService.instance.groups
                          .firstWhere((g) => g.id == _group.id,
                              orElse: () => _group);
                      _group = updated;
                    }),
                  ),
                ),
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${_group.pendingRequests.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ]),
          IconButton(icon: Icon(Icons.person_add_rounded, color: TColor.primary),
              onPressed: _inviteMember, tooltip: 'Mời thành viên'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'disband') _disbandGroup();
              if (v == 'remove') _showRemoveMemberDialog();
              if (v == 'leave') _leaveGroup();
            },
            itemBuilder: (_) => _isAdmin
                ? [
                    const PopupMenuItem(value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.person_remove_rounded, color: Colors.orange),
                          title: Text('Xóa thành viên', style: TextStyle(color: Colors.orange)),
                          contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(value: 'disband',
                        child: ListTile(
                          leading: Icon(Icons.exit_to_app_rounded, color: Colors.red),
                          title: Text('Giải tán nhóm', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero)),
                  ]
                : [
                    const PopupMenuItem(value: 'leave',
                        child: ListTile(
                          leading: Icon(Icons.logout_rounded, color: Colors.red),
                          title: Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero)),
                  ],
          ),
        ],
      ),
      body: GroupChatTab(
        messages: _messages,
        myId: _myId,
        isLoading: _isLoadingChat,
        members: _group.members,
        onSendText: _sendText,
        onSendImage: () async {},
      ),
    );
  }
}
