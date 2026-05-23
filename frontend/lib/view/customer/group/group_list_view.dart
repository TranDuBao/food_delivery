import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'group_model.dart';
import 'group_service.dart';
import 'group_detail_view.dart';

class GroupListView extends StatefulWidget {
  const GroupListView({super.key});

  @override
  State<GroupListView> createState() => _GroupListViewState();
}

class _GroupListViewState extends State<GroupListView> {
  bool _loading = false;

  List<GroupModel> get _groups => GroupService.instance.groups.toList();

  Future<void> _reloadFromAPI() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await GroupService.instance.reloadGroupsFromAPI();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _reloadFromAPI();
  }

  void _refresh() => setState(() {});

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tạo nhóm mới',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Tên nhóm...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tạo', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await GroupService.instance.createGroup(result);
      setState(() {});
      if (mounted) {
        AppNotification.show(context,
            message: 'Tạo nhóm "$result" thành công!',
            type: NotifType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Nhóm của tôi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Column(
            children: [
              if (_loading)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(TColor.primary),
                  minHeight: 2,
                ),
              Container(height: 1, color: Colors.grey.shade100),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: TColor.primary, size: 28),
            onPressed: _createGroup,
            tooltip: 'Tạo nhóm mới',
          ),
        ],
      ),
      body: groups.isEmpty
          ? _EmptyGroupPlaceholder(onCreateTap: _createGroup)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (_, i) => _GroupCard(
                group: groups[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailView(group: groups[i]),
                  ),
                ).then((_) => _reloadFromAPI()),
                onDelete: () async {
                  final ok = await AppNotification.confirm(context,
                      title: 'Xoá nhóm',
                      message: 'Bạn có chắc muốn xoá nhóm "${groups[i].name}"?',
                      confirmText: 'Xoá',
                      cancelText: 'Huỷ');
                  if (ok == true) {
                    await GroupService.instance.deleteGroup(groups[i].id);
                    setState(() {});
                  }
                },
              ),
            ),
      floatingActionButton: groups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createGroup,
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo nhóm',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyGroupPlaceholder extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyGroupPlaceholder({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Chưa có nhóm nào',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              'Tạo nhóm để cùng đặt đồ ăn và chia sẻ ngân sách với bạn bè!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo nhóm mới',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group Card ───────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _GroupCard(
      {required this.group, required this.onTap, required this.onDelete});

  String _formatBalance(double b) =>
      '${b.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      TColor.primary.withValues(alpha: 0.12),
                  backgroundImage: group.avatarUrl != null
                      ? NetworkImage(group.avatarUrl!)
                      : null,
                  child: group.avatarUrl == null
                      ? Text(group.name[0].toUpperCase(),
                          style: TextStyle(
                              color: TColor.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.people_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${group.members.length} thành viên',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.account_balance_wallet_rounded,
                            size: 13, color: Color(0xFF2ECC71)),
                        const SizedBox(width: 3),
                        Text(
                          _formatBalance(group.wallet?.balance ?? 0),
                          style: const TextStyle(
                              color: Color(0xFF2ECC71),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Mã: ${group.referralCode}',
                          style: TextStyle(
                              color: TColor.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
