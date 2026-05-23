// lib/view/customer/group/chat_service.dart
// Lưu trữ tin nhắn nhóm vào SharedPreferences theo groupId

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_model.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const int _maxMessages = 200; // giới hạn lưu mỗi nhóm

  String _key(String groupId) => 'chat_msgs_$groupId';

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<List<GroupMessage>> loadMessages(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(groupId));
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(GroupMessage.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Save all ──────────────────────────────────────────────────────────────
  Future<void> saveMessages(String groupId, List<GroupMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Chỉ giữ lại _maxMessages tin nhắn cuối
      final toSave = messages.length > _maxMessages
          ? messages.sublist(messages.length - _maxMessages)
          : messages;
      await prefs.setString(_key(groupId), jsonEncode(toSave.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  // ── Append one ────────────────────────────────────────────────────────────
  Future<void> appendMessage(String groupId, GroupMessage msg) async {
    final current = await loadMessages(groupId);
    current.add(msg);
    await saveMessages(groupId, current);
  }

  // ── Mark seen ─────────────────────────────────────────────────────────────
  /// Đánh dấu userId đã đọc những tin nhắn chưa thấy
  Future<List<GroupMessage>> markSeen(
      String groupId, String userId, List<GroupMessage> messages) async {
    bool changed = false;
    final updated = messages.map((m) {
      final seenBy = List<String>.from(m.seenBy); // guard null từ data cũ
      if (m.senderId != userId && !seenBy.contains(userId)) {
        changed = true;
        return m.copyWithSeen([...seenBy, userId]);
      }
      return m;
    }).toList();
    if (changed) await saveMessages(groupId, updated);
    return updated;
  }

  // ── Clear ─────────────────────────────────────────────────────────────────
  Future<void> clearMessages(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(groupId));
  }
}
