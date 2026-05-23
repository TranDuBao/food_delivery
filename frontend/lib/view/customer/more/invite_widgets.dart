// lib/view/customer/more/invite_widgets.dart
// Các widget dùng lại trong trang mời bạn bè

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import '../group/group_detail_view.dart';
import '../group/group_list_view.dart';
import '../group/group_service.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common/app_notification.dart';

// ─── Shared card container ────────────────────────────────────────────────────
class InviteCard extends StatelessWidget {
  final Widget child;
  const InviteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16, offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class InviteStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const InviteStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10, offset: const Offset(0, 3))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ),
      );
}

// ─── Share button ─────────────────────────────────────────────────────────────
class InviteShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const InviteShareBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ─── Step widget ──────────────────────────────────────────────────────────────
class InviteStep extends StatelessWidget {
  final String step, title, desc;
  final Color color;
  final bool isLast;

  const InviteStep({
    super.key,
    required this.step,
    required this.title,
    required this.desc,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(step,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: Colors.grey.shade200),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12, height: 1.4)),
              ]),
            ),
          ),
        ],
      );
}

// ─── Invite Input Bottom Sheet ────────────────────────────────────────────────
class InviteSheet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, hint;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  const InviteSheet({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.hint,
    required this.keyboardType,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: InputDecoration(
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color, width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () => onSend(controller.text.trim()),
                icon: Icon(icon),
                label: const Text('Gửi lời mời',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─── Inline Group Tile ────────────────────────────────────────────────────────
class InlineGroupTile extends StatelessWidget {
  final dynamic group;
  final VoidCallback onTap;

  const InlineGroupTile({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final balance = (group.wallet?.balance as double?) ?? 0.0;
    final fmt = balance
            .toStringAsFixed(0)
            .replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') +
        ' đ';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: TColor.primary.withValues(alpha: 0.12),
            child: Text(group.name[0].toUpperCase(),
                style: TextStyle(
                    color: TColor.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              Row(children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 12, color: Color(0xFF2ECC71)),
                const SizedBox(width: 3),
                Text(fmt,
                    style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.people_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 3),
                Text('${(group.members as List).length} TV',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }
}

// ─── My Groups card ───────────────────────────────────────────────────────────
class MyGroupsCard extends StatefulWidget {
  final BuildContext parentContext;
  const MyGroupsCard({super.key, required this.parentContext});

  @override
  State<MyGroupsCard> createState() => MyGroupsCardState();
}

class MyGroupsCardState extends State<MyGroupsCard> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await GroupService.instance.reloadGroupsFromAPI();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final groups = GroupService.instance.groups;
    return InviteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Nhóm của tôi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          if (_loading)
            const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
          TextButton.icon(
            onPressed: () => Navigator.push(widget.parentContext,
                    MaterialPageRoute(builder: (_) => const GroupListView()))
                .then((_) => _reload()),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
            label: const Text('Xem tất cả'),
            style: TextButton.styleFrom(foregroundColor: TColor.primary),
          ),
        ]),
        const SizedBox(height: 8),
        if (groups.isEmpty) ...[
          const Text('Bạn chưa có nhóm nào.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(widget.parentContext,
                      MaterialPageRoute(builder: (_) => const GroupListView()))
                  .then((_) => _reload()),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tạo nhóm mới',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ] else ...[
          ...groups.take(3).map((g) => InlineGroupTile(
                group: g,
                onTap: () => Navigator.push(widget.parentContext,
                        MaterialPageRoute(builder: (_) => GroupDetailView(group: g)))
                    .then((_) => _reload()),
              )),
          if (groups.length > 3)
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(widget.parentContext,
                        MaterialPageRoute(builder: (_) => const GroupListView()))
                    .then((_) => _reload()),
                child: Text('+${groups.length - 3} nhóm khác',
                    style: TextStyle(
                        color: TColor.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(widget.parentContext,
                      MaterialPageRoute(builder: (_) => const GroupListView()))
                  .then((_) => _reload()),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tạo nhóm mới',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.primary,
                side: BorderSide(color: TColor.primary),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── GroupNotificationsCard ──────────────────────────────────────────────────
class GroupNotificationsCard extends StatelessWidget {
  final BuildContext parentContext;
  final GlobalKey<MyGroupsCardState>? groupsCardKey;

  const GroupNotificationsCard({
    super.key,
    required this.parentContext,
    this.groupsCardKey,
  });

  static String _resolveEmail(Map<dynamic, dynamic> p) =>
      p['email']?.toString() ?? p['taiKhoan']?.toString() ?? '';

  static String _resolveId(Map<dynamic, dynamic> p) =>
      p['id']?.toString() ?? p['_id']?.toString() ?? p['maTaiKhoan']?.toString() ?? '';

  static String _resolveName(Map<dynamic, dynamic> p) =>
      p['hoTen']?.toString() ?? p['name']?.toString() ?? 'Bạn';

  @override
  Widget build(BuildContext context) {
    final payload = ServiceCall.userPayload;
    final email = _resolveEmail(payload);
    final myId = _resolveId(payload);
    final myName = _resolveName(payload);

    return StatefulBuilder(
      builder: (ctx, setInner) {
        final invitations = GroupService.instance.getInvitationsForEmail(email);
        if (invitations.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InviteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Thông báo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                ...invitations.map((inv) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Bạn được mời tham gia nhóm '),
                                TextSpan(text: inv.groupName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await GroupService.instance.rejectInvitation(inv.id);
                                    setInner(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await GroupService.instance.acceptInvitation(inv.id, myId, myName);
                                    setInner(() {});
                                    // Reload danh sách nhóm ngay lập tức
                                    groupsCardKey?.currentState?._reload();
                                    AppNotification.show(parentContext,
                                        message: 'Đã tham gia nhóm ${inv.groupName}',
                                        type: NotifType.success);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
