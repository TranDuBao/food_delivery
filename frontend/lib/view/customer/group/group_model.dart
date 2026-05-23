// lib/view/customer/group/group_model.dart
// Data models cho tính năng Nhóm.

class GroupMember {
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isAdmin;

  const GroupMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isAdmin = false,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        userId: json['userId']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        isAdmin: json['isAdmin'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
        'isAdmin': isAdmin,
      };
}

// ─── Join Request ─────────────────────────────────────────────────────────────
class JoinRequest {
  final String userId;
  final String userName;
  final DateTime requestedAt;

  const JoinRequest({
    required this.userId,
    required this.userName,
    required this.requestedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        requestedAt:
            DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'requestedAt': requestedAt.toIso8601String(),
      };
}

// ─── GroupMessage ─────────────────────────────────────────────────────────────
class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;
  final List<String> seenBy; // userIds đã đọc tin nhắn này

  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.imageUrl,
    required this.timestamp,
    this.seenBy = const [],
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        text: json['text']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        seenBy: List<String>.from((json['seenBy'] as List?) ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'timestamp': timestamp.toIso8601String(),
        'seenBy': seenBy,
      };

  GroupMessage copyWithSeen(List<String> newSeenBy) => GroupMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        imageUrl: imageUrl,
        timestamp: timestamp,
        seenBy: newSeenBy,
      );
}

// ─── GroupWallet ──────────────────────────────────────────────────────────────
class GroupWallet {
  final String groupId;
  final double balance;
  final String qrCode;
  final List<WalletTransaction> transactions;

  const GroupWallet({
    required this.groupId,
    required this.balance,
    required this.qrCode,
    this.transactions = const [],
  });

  factory GroupWallet.fromJson(Map<String, dynamic> json) => GroupWallet(
        groupId: json['groupId']?.toString() ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        qrCode: json['qrCode']?.toString() ?? '',
        transactions: (json['transactions'] as List? ?? [])
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'balance': balance,
        'qrCode': qrCode,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
}

// ─── WalletTransaction ────────────────────────────────────────────────────────
class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'deposit',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        description: json['description']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'description': description,
        'userId': userId,
        'userName': userName,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ─── GroupModel ───────────────────────────────────────────────────────────────
class GroupModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<GroupMember> members;
  final GroupWallet? wallet;
  final String referralCode;
  final DateTime createdAt;
  final List<JoinRequest> pendingRequests;
  final String ownerId; // userId của người tạo nhóm

  const GroupModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.members,
    this.wallet,
    required this.referralCode,
    required this.createdAt,
    this.pendingRequests = const [],
    this.ownerId = '',
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        members: (json['members'] as List? ?? [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        wallet: json['wallet'] != null
            ? GroupWallet.fromJson(json['wallet'] as Map<String, dynamic>)
            : null,
        referralCode: json['referralCode']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        pendingRequests: (json['pendingRequests'] as List? ?? [])
            .map((e) => JoinRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        ownerId: json['ownerId']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'referralCode': referralCode,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'wallet': wallet?.toJson(),
        'pendingRequests': pendingRequests.map((r) => r.toJson()).toList(),
      };

  GroupModel copyWith({
    String? name,
    String? avatarUrl,
    List<GroupMember>? members,
    GroupWallet? wallet,
    List<JoinRequest>? pendingRequests,
  }) =>
      GroupModel(
        id: id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        members: members ?? this.members,
        wallet: wallet ?? this.wallet,
        referralCode: referralCode,
        createdAt: createdAt,
        ownerId: ownerId,
        pendingRequests: pendingRequests ?? this.pendingRequests,
      );
}

// ─── GroupInvitation ──────────────────────────────────────────────────────────
class GroupInvitation {
  final String id;
  final String groupId;
  final String groupName;
  final String invitedEmail;
  final DateTime invitedAt;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.invitedEmail,
    required this.invitedAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) => GroupInvitation(
        id: json['id']?.toString() ?? '',
        groupId: json['groupId']?.toString() ?? '',
        groupName: json['groupName']?.toString() ?? '',
        invitedEmail: json['invitedEmail']?.toString() ?? '',
        invitedAt: DateTime.tryParse(json['invitedAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'groupName': groupName,
        'invitedEmail': invitedEmail,
        'invitedAt': invitedAt.toIso8601String(),
      };
}
