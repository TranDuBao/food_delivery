// lib/view/customer/group/group_chat_tab.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'group_model.dart';

// Bảng màu cố định cho từng thành viên (theo index / hash)
const _memberColors = [
  Color(0xFF6C63FF),
  Color(0xFF2ECC71),
  Color(0xFFE74C3C),
  Color(0xFF3498DB),
  Color(0xFFE67E22),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
  Color(0xFFE91E63),
];

Color _colorForSender(String senderId) {
  final hash = senderId.codeUnits.fold(0, (a, b) => a + b);
  return _memberColors[hash % _memberColors.length];
}

class GroupChatTab extends StatefulWidget {
  final List<GroupMessage> messages;
  final String myId;
  final bool isLoading;
  final List<GroupMember> members;
  final Future<void> Function(String text) onSendText;
  final Future<void> Function() onSendImage;

  const GroupChatTab({
    super.key,
    required this.messages,
    required this.myId,
    this.isLoading = false,
    this.members = const [],
    required this.onSendText,
    required this.onSendImage,
  });

  @override
  State<GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends State<GroupChatTab> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    await widget.onSendText(text);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    await widget.onSendImage();
    if (mounted) {
      AppNotification.show(context,
          message: 'Đã chọn ảnh. Tính năng upload đang phát triển.',
          type: NotifType.info);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : widget.messages.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 60, color: Colors.black12),
                      SizedBox(height: 12),
                      Text('Chưa có tin nhắn nào',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                    ]),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: widget.messages.length,
                    itemBuilder: (_, i) {
                      final msg = widget.messages[i];

                      // System message — hiển thị dạng banner thông báo
                      if (msg.senderId == 'system') {
                        return _SystemMessageBubble(text: msg.text ?? '');
                      }

                      final isMe = msg.senderId == widget.myId;
                      final isLast = i == widget.messages.length - 1;
                      final seenList = msg.seenBy;
                      final seenOthers = seenList
                          .where((id) => id != msg.senderId)
                          .toList();

                      return ChatBubble(
                        msg: msg,
                        isMe: isMe,
                        isLast: isLast,
                        seenOthers: seenOthers,
                        allMembers: widget.members,
                      );
                    },
                  ),
      ),
      // Input bar
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            IconButton(
              onPressed: _pickImage,
              icon: Icon(Icons.image_rounded, color: TColor.primary),
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: TColor.primary,
              child: IconButton(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Chat Bubble ─────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final GroupMessage msg;
  final bool isMe;
  final bool isLast;
  final List<String> seenOthers;
  final List<GroupMember> allMembers;

  const ChatBubble({
    super.key,
    required this.msg,
    required this.isMe,
    this.isLast = false,
    this.seenOthers = const [],
    this.allMembers = const [],
  });

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String? _memberName(String userId) {
    final m = allMembers.cast<GroupMember?>().firstWhere(
        (m) => m?.userId == userId,
        orElse: () => null);
    return m?.name;
  }

  @override
  Widget build(BuildContext context) {
    final senderColor = isMe ? TColor.primary : _colorForSender(msg.senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Avatar người gửi (bên trái)
              if (!isMe) ...[
                _Avatar(
                    name: msg.senderName, color: senderColor, radius: 16),
                const SizedBox(width: 8),
              ],

              // Bubble + timestamp
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Tên người gửi
                    if (!isMe)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 3, left: 4),
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                              color: senderColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),

                    // Bubble
                    if (msg.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(msg.imageUrl!,
                            width: 200, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.68),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? senderColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: senderColor.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          msg.text ?? '',
                          style: TextStyle(
                              color:
                                  isMe ? Colors.white : Colors.black87,
                              fontSize: 14,
                              height: 1.4),
                        ),
                      ),

                    // Thời gian
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                      child: Text(
                        _fmt(msg.timestamp),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),

              // Placeholder bên phải cho tin nhắn của người khác (căn chỉnh)
              if (!isMe) const SizedBox(width: 32),
            ],
          ),

          // ── Seen by ──────────────────────────────────────────────────────
          if (isMe && seenOthers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.done_all_rounded,
                      size: 13, color: Colors.blue),
                  const SizedBox(width: 4),
                  // Avatar nhỏ của từng người đã xem
                  ...seenOthers.take(5).map((uid) {
                    final name = _memberName(uid) ?? uid;
                    final color = _colorForSender(uid);
                    return Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Tooltip(
                        message: name,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: color,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (seenOthers.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text('+${seenOthers.length - 5}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double radius;

  const _Avatar(
      {required this.name, required this.color, this.radius = 18});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.18),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.7),
        ),
      );
}

// -- System Message Bubble (thong bao dat mon nhom) --------------------------
class _SystemMessageBubble extends StatelessWidget {
  final String text;
  const _SystemMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('???', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF5D4037), fontSize: 13, height: 1.5),
          ),
        ),
      ]),
    );
  }
}
