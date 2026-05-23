// lib/view/customer/group/group_requests_tab.dart
// Tab / sheet hiển thị danh sách yêu cầu tham gia nhóm (chỉ chủ nhóm thấy)

import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'group_model.dart';
import 'group_service.dart';

class GroupRequestsSheet extends StatefulWidget {
  final GroupModel group;
  final VoidCallback onChanged;

  const GroupRequestsSheet({
    super.key,
    required this.group,
    required this.onChanged,
  });

  @override
  State<GroupRequestsSheet> createState() => _GroupRequestsSheetState();
}

class _GroupRequestsSheetState extends State<GroupRequestsSheet> {
  late List<JoinRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List.from(widget.group.pendingRequests);
  }

  Future<void> _approve(JoinRequest req) async {
    await GroupService.instance.approveRequest(
        widget.group.id, req.userId, req.userName);
    setState(() => _requests.removeWhere((r) => r.userId == req.userId));
    widget.onChanged();
    if (mounted) {
      AppNotification.show(context,
          title: 'Đã chấp nhận!',
          message: '${req.userName} đã tham gia nhóm.',
          type: NotifType.success);
    }
  }

  Future<void> _reject(JoinRequest req) async {
    await GroupService.instance.rejectRequest(widget.group.id, req.userId);
    setState(() => _requests.removeWhere((r) => r.userId == req.userId));
    widget.onChanged();
    if (mounted) {
      AppNotification.show(context,
          message: 'Đã từ chối ${req.userName}.',
          type: NotifType.info);
    }
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
              child: Text('Yêu cầu tham gia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_requests.length} yêu cầu',
                  style: TextStyle(
                      color: TColor.primary,
                      fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: _requests.isEmpty
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 56, color: Colors.green),
                    SizedBox(height: 10),
                    Text('Không có yêu cầu nào',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final req = _requests[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              TColor.primary.withValues(alpha: 0.12),
                          child: Text(req.userName.isNotEmpty
                              ? req.userName[0].toUpperCase()
                              : '?',
                              style: TextStyle(
                                  color: TColor.primary,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(req.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(_fmt(req.requestedAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                        ])),
                        // Reject
                        IconButton(
                          onPressed: () => _reject(req),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.red, size: 22),
                          tooltip: 'Từ chối',
                        ),
                        // Approve
                        ElevatedButton(
                          onPressed: () => _approve(req),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Duyệt',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
