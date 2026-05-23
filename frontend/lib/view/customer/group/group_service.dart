import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common/globs.dart';
import 'group_model.dart';

class GroupService {
  GroupService._();
  static final GroupService instance = GroupService._();

  // Tất cả nhóm trên thiết bị (global registry)
  List<GroupModel> _allGroups = [];
  List<GroupInvitation> _invitations = [];
  String _currentUserId = '';

  /// Trả về nhóm mà user hiện tại là thành viên HOẶC là chủ tạo ra
  List<GroupModel> get groups {
    if (_currentUserId.isEmpty) return [];
    return _allGroups.where((g) {
      // So sánh an toàn (vì DB có thể trả về Int hoặc String)
      final isOwner = g.ownerId.toString() == _currentUserId.toString();
      final isMember = g.members.any((m) => m.userId.toString() == _currentUserId.toString());
      return isOwner || isMember;
    }).toList();
  }

  // Key toàn cục — dùng chung cho mọi tài khoản trên thiết bị
  static const String _registryKey = 'group_registry_v1';
  static const String _invitationsKey = 'group_invitations_v1';

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initForUser(String userId) async {
    _currentUserId = userId;
    print("GroupService: Initializing for user $userId");
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        // Lấy từ API
        final res = await ServiceCall.fetchPost(SVKey.svMyGroups, body: {
          'user_id': userId,
        }, isToken: true);
        
        if (res['success'] == true && res['data'] != null) {
          final list = res['data'] as List;
          print("GroupService: API returned ${list.length} groups");
          _allGroups = list
              .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
              .toList();
          await _persist();
        } else {
          throw Exception("API Failed");
        }
      } catch (e) {
        print("GroupService API Error: $e. Falling back to local.");
        // Fallback local
        final raw = prefs.getString(_registryKey);
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          _allGroups = list
              .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _allGroups = [];
        }
      }

      final rawInv = prefs.getString(_invitationsKey);
      if (rawInv != null) {
        final list = jsonDecode(rawInv) as List;
        _invitations = list
            .map((e) => GroupInvitation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _invitations = [];
      }
    } catch (e) {
      print("GroupService Global Init Error: $e");
      _allGroups = [];
      _invitations = [];
    }
  }

  void clearSession() {
    _currentUserId = '';
  }

  /// Tải lại danh sách nhóm từ API (dùng khi cần refresh UI)
  Future<void> reloadGroupsFromAPI() async {
    if (_currentUserId.isEmpty) return;
    print("GroupService: Reloading groups from API for user $_currentUserId");
    try {
      final res = await ServiceCall.fetchPost(SVKey.svMyGroups, body: {
        'user_id': _currentUserId,
      }, isToken: true);
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        print("GroupService: API Reload returned ${list.length} groups");
        _allGroups = list
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _persist();
      }
    } catch (e) {
      print("GroupService Reload API Error: $e");
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _registryKey,
        jsonEncode(_allGroups.map((g) => g.toJson()).toList()));
    await prefs.setString(
        _invitationsKey,
        jsonEncode(_invitations.map((i) => i.toJson()).toList()));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<GroupModel> createGroup(String name) async {
    try {
      final res = await ServiceCall.fetchPost(SVKey.svGroupsCreate, body: {
        'name': name,
      }, isToken: true);

      if (res['success'] == true && res['data'] != null) {
        final group = GroupModel.fromJson(res['data'] as Map<String, dynamic>);
        _allGroups.insert(0, group);
        await _persist();
        return group;
      }
    } catch (_) {
      // Fallback if API fails
    }

    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final group = GroupModel(
      id: id,
      name: name,
      ownerId: _currentUserId,
      members: [],
      referralCode: code,
      createdAt: DateTime.now(),
      wallet: GroupWallet(groupId: id, balance: 0, qrCode: 'GRPWALLET-$code'),
    );
    _allGroups.insert(0, group);
    await _persist();
    return group;
  }

  Future<void> updateGroup(GroupModel updated) async {
    final idx = _allGroups.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _allGroups[idx] = updated;
      await _persist();
    }
  }

  Future<void> deleteGroup(String id) async {
    _allGroups.removeWhere((g) => g.id == id);
    await _persist();
  }

  // ── Join Request Flow ──────────────────────────────────────────────────────

  /// Tìm nhóm theo mã (tìm trong toàn bộ registry)
  /// Trả về: 'ok' | 'not_found' | 'already_member' | 'already_requested'
  Future<String> requestToJoin({
    required String groupCode,
    required String userId,
    required String userName,
  }) async {
    final idx = _allGroups.indexWhere(
        (g) => g.referralCode.toUpperCase() == groupCode.toUpperCase());
    if (idx == -1) return 'not_found';

    final group = _allGroups[idx];
    if (group.ownerId == userId) return 'already_member';
    if (group.members.any((m) => m.userId == userId)) return 'already_member';
    if (group.pendingRequests.any((r) => r.userId == userId)) {
      return 'already_requested';
    }

    final updated = group.copyWith(
      pendingRequests: [
        ...group.pendingRequests,
        JoinRequest(
            userId: userId,
            userName: userName,
            requestedAt: DateTime.now()),
      ],
    );
    _allGroups[idx] = updated;
    await _persist();
    return 'ok';
  }

  /// Chủ nhóm chấp nhận yêu cầu tham gia
  Future<void> approveRequest(
      String groupId, String requestUserId, String requestUserName) async {
    final idx = _allGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final group = _allGroups[idx];
    final newMembers = [
      ...group.members,
      GroupMember(userId: requestUserId, name: requestUserName),
    ];
    final newRequests =
        group.pendingRequests.where((r) => r.userId != requestUserId).toList();
    _allGroups[idx] =
        group.copyWith(members: newMembers, pendingRequests: newRequests);
    await _persist();
  }

  /// Chủ nhóm từ chối yêu cầu tham gia
  Future<void> rejectRequest(String groupId, String requestUserId) async {
    final idx = _allGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final group = _allGroups[idx];
    final newRequests =
        group.pendingRequests.where((r) => r.userId != requestUserId).toList();
    _allGroups[idx] = group.copyWith(pendingRequests: newRequests);
    await _persist();
  }

  // ── Invitations Flow ──────────────────────────────────────────────────────
  
  /// Mời thành viên bằng email
  Future<void> inviteMember(String groupId, String email) async {
    final idx = _allGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    
    // Nếu email này đã được mời vào nhóm này rồi thì bỏ qua
    if (_invitations.any((inv) => inv.groupId == groupId && inv.invitedEmail.toLowerCase() == email.toLowerCase())) {
      return;
    }

    final group = _allGroups[idx];
    final inv = GroupInvitation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      groupName: group.name,
      invitedEmail: email,
      invitedAt: DateTime.now(),
    );
    _invitations.insert(0, inv);
    await _persist();
  }

  /// Lấy danh sách lời mời của 1 email
  List<GroupInvitation> getInvitationsForEmail(String email) {
    if (email.isEmpty) return [];
    return _invitations.where((inv) => inv.invitedEmail.toLowerCase() == email.toLowerCase()).toList();
  }

  /// Chấp nhận lời mời
  Future<void> acceptInvitation(String invitationId, String userId, String userName) async {
    final idxInv = _invitations.indexWhere((inv) => inv.id == invitationId);
    if (idxInv == -1) return;
    final inv = _invitations[idxInv];

    // Gọi API để lưu vào database
    try {
      await ServiceCall.fetchPost(SVKey.svGroupJoin, body: {
        'groupId': inv.groupId,
      }, isToken: true);
    } catch (_) {
      // Nếu API lỗi thì vẫn cập nhật local để UX không bị gián đoạn
    }

    // Cập nhật local cache
    final idxGroup = _allGroups.indexWhere((g) => g.id == inv.groupId);
    if (idxGroup != -1) {
      final group = _allGroups[idxGroup];
      if (!group.members.any((m) => m.userId == userId) && group.ownerId != userId) {
        final newMembers = [
          ...group.members,
          GroupMember(userId: userId, name: userName),
        ];
        _allGroups[idxGroup] = group.copyWith(members: newMembers);
      }
    } else {
      // Nhóm chưa có trong cache → reload từ API
      await initForUser(userId);
    }

    // Xóa lời mời sau khi chấp nhận
    _invitations.removeAt(idxInv);
    await _persist();
  }

  /// Từ chối/hủy lời mời
  Future<void> rejectInvitation(String invitationId) async {
    _invitations.removeWhere((inv) => inv.id == invitationId);
    await _persist();
  }
}
