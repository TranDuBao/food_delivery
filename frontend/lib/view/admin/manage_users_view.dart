// lib/view/admin/manage_users_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});
  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<int, List<Map<String, dynamic>>> _usersByRole = {};
  bool _loading = true;

  static int _safeInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool _safeBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v == 'true';
    return false;
  }

  static const _roleLabels = {1: 'Khách hàng', 2: 'Nhân viên'};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAdminUsers, isToken: true);
      if (res is Map && res['success'] == true) {
        final all = (res['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final Map<int, List<Map<String, dynamic>>> grouped = {1: [], 2: []};
        for (final u in all) {
          // Bỏ qua tài khoản bị xóa mềm (trangThai=0 và không có thông tin khóa)
          final isActive = _safeInt(u['trangThai']) == 1;
          final isLocked = !isActive &&
              (_safeBool(u['khoaVinhVien']) || u['thoiGianKhoa'] != null);
          if (!isActive && !isLocked) continue; // xóa mềm → ẩn đi

          final role = _safeInt(u['maVaiTro']);
          if (grouped.containsKey(role)) grouped[role]!.add(u);
        }
        setState(() => _usersByRole = grouped);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── Thông tin khóa ────────────────────────────────────────────────
  String _banLabel(Map<String, dynamic> user) {
    final isActive = _safeInt(user['trangThai']) == 1;
    if (isActive) return 'Đang hoạt động';
    if (_safeBool(user['khoaVinhVien'])) return 'Khóa vĩnh viễn';
    final rawDate = user['thoiGianKhoa'];
    if (rawDate != null) {
      try {
        final unlock = DateTime.parse(rawDate.toString());
        final diff = unlock.difference(DateTime.now());
        if (!diff.isNegative) return 'Còn ${diff.inDays + 1} ngày';
      } catch (_) {}
    }
    return 'Đã bị khóa';
  }

  // ── Dialog khóa / mở khóa ────────────────────────────────────────
  Future<void> _showBanDialog(Map<String, dynamic> user) async {
    final isActive = _safeInt(user['trangThai']) == 1;
    final daysCtrl = TextEditingController(text: '7');

    if (!isActive) {
      // Hiển thị thông tin khóa hiện tại + nút mở khóa
      final isForever = _safeBool(user['khoaVinhVien']);
      final rawDate = user['thoiGianKhoa'];
      String lockInfo = 'Tài khoản đang bị khóa.';
      int? daysLeft;
      if (isForever) {
        lockInfo = 'Tài khoản bị khóa vĩnh viễn.';
      } else if (rawDate != null) {
        try {
          final unlock = DateTime.parse(rawDate.toString());
          final diff = unlock.difference(DateTime.now());
          if (!diff.isNegative) {
            daysLeft = diff.inDays + 1;
            lockInfo = 'Tài khoản bị khóa tạm thời.';
          }
        } catch (_) {}
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(
              isForever ? Icons.lock_rounded : Icons.lock_clock_rounded,
              color: isForever ? Colors.red : Colors.orange,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text('Trạng thái khóa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isForever ? Colors.red : Colors.orange).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isForever ? Colors.red : Colors.orange).withValues(alpha: 0.3),
                ),
              ),
              child: Column(children: [
                Icon(
                  isForever ? Icons.all_inclusive_rounded : Icons.timer_outlined,
                  color: isForever ? Colors.red : Colors.orange,
                  size: 28,
                ),
                const SizedBox(height: 6),
                if (daysLeft != null) ...[
                  Text('$daysLeft ngày',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade700)),
                  const Text('còn lại',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(height: 4),
                Text(lockInfo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: isForever ? Colors.red : Colors.orange.shade800,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('Bạn có muốn mở khóa tài khoản này?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Đóng')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Mở khóa', style: TextStyle(color: Colors.white)),
              ]),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await ServiceCall.fetchPut(
            SVKey.svAdminUpdateUser(user['maTaiKhoan']),
            isToken: true,
            body: {'action': 'unban'});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Đã mở khóa tài khoản!')));
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Lỗi mở khóa: $e')));
        }
      }
      return;
    }

    // Đang active → chọn loại khóa
    String selected = 'days';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.lock_rounded, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Khóa: ${user['hoTen']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _BanOption(
              selected: selected == 'days',
              color: Colors.orange,
              onTap: () => setD(() => selected = 'days'),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Khóa theo số ngày',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (selected == 'days') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Số ngày (vd: 7)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      suffixText: 'ngày',
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 10),
            _BanOption(
              selected: selected == 'forever',
              color: Colors.red,
              onTap: () => setD(() => selected = 'forever'),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Khóa vĩnh viễn',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.red)),
                Text('Không có thời hạn, phải mở thủ công',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selected == 'forever' ? Colors.red : Colors.orange),
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Xác nhận khóa',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    try {
      if (result == 'forever') {
        await ServiceCall.fetchPut(
            SVKey.svAdminUpdateUser(user['maTaiKhoan']),
            isToken: true,
            body: {'action': 'ban_forever'});
      } else {
        final days = int.tryParse(daysCtrl.text.trim()) ?? 7;
        if (days <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Số ngày phải lớn hơn 0!')));
          }
          return;
        }
        await ServiceCall.fetchPut(
            SVKey.svAdminUpdateUser(user['maTaiKhoan']),
            isToken: true,
            body: {'action': 'ban_days', 'soNgay': days});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔒 Đã khóa tài khoản!')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khóa tài khoản: $e')));
      }
    }
  }

  // ── Xóa mềm ──────────────────────────────────────────────────────
  Future<void> _softDelete(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Xóa tài khoản'),
        content: Text(
            'Tài khoản "${user['hoTen']}" sẽ bị vô hiệu hóa.\nBạn có thể active lại bất cứ lúc nào.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ServiceCall.fetchDelete(
          SVKey.svAdminDeleteUser(user['maTaiKhoan']),
          isToken: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã xóa tài khoản.')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // ── Sửa thông tin (không có vai trò) ─────────────────────────────
  void _showEditDialog(Map<String, dynamic> user) {
    final hoTenCtrl =
        TextEditingController(text: user['hoTen']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: user['email']?.toString() ?? '');
    final sdtCtrl =
        TextEditingController(text: user['soDienThoai']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('✏️ Sửa: ${user['hoTen']}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(hoTenCtrl, 'Họ tên'),
            _field(emailCtrl, 'Email'),
            _field(sdtCtrl, 'Số điện thoại'),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              try {
                await ServiceCall.fetchPut(
                    SVKey.svAdminUpdateUser(user['maTaiKhoan']),
                    isToken: true,
                    body: {
                      'hoTen': hoTenCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'soDienThoai': sdtCtrl.text.trim(),
                    });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Cập nhật thành công!')));
                }
                _load();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Thêm tài khoản nhân viên mới ─────────────────────────────────
  void _showCreateDialog() {
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final hoTenCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final sdtCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.badge_rounded, color: Color(0xFF6C63FF), size: 22),
          SizedBox(width: 8),
          Text('Tạo tài khoản Nhân viên',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(usernameCtrl, 'Tên đăng nhập *'),
            _field(passCtrl, 'Mật khẩu *', obscure: true),
            _field(hoTenCtrl, 'Họ tên'),
            _field(emailCtrl, 'Email'),
            _field(sdtCtrl, 'Số điện thoại'),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (usernameCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Vui lòng điền tên đăng nhập và mật khẩu.')));
                return;
              }
              try {
                final res = await ServiceCall.fetchPost(
                    SVKey.svAdminUsers,
                    isToken: true,
                    body: {
                      'tenDangNhap': usernameCtrl.text.trim(),
                      'matKhau': passCtrl.text,
                      'hoTen': hoTenCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'soDienThoai': sdtCtrl.text.trim(),
                      'maVaiTro': 2, // Luôn là Nhân viên
                    });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (res is Map && res['success'] == true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ Tạo tài khoản nhân viên thành công!')));
                  }
                  // Chuyển sang tab Nhân viên
                  _tabCtrl.animateTo(1);
                  _load();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res is Map
                            ? (res['message'] ?? 'Lỗi')
                            : 'Lỗi')));
                  }
                }
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Tạo Nhân viên',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
          {bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      );

  // ── Card tài khoản ───────────────────────────────────────────────
  Widget _buildUserCard(Map<String, dynamic> u) {
    final isActive = _safeInt(u['trangThai']) == 1;
    final isForever = _safeBool(u['khoaVinhVien']);
    final label = _banLabel(u);

    // Màu theme theo trạng thái
    final Color themeColor = isActive
        ? const Color(0xFF6C63FF)
        : isForever
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : themeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.black : themeColor)
                .withValues(alpha: isActive ? 0.05 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // ── Header màu khi bị khóa ────────────────────────────────
        if (!isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Icon(
                isForever ? Icons.lock_rounded : Icons.lock_clock_rounded,
                color: themeColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: themeColor,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              // Nút mở khóa nhanh
              GestureDetector(
                onTap: () => _showBanDialog(u),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open_rounded,
                          color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text('Mở khóa',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        // ── Nội dung chính ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: themeColor.withValues(alpha: 0.12),
              child: Text(
                (u['hoTen']?.toString() ?? '?')
                    .substring(0, 1)
                    .toUpperCase(),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: themeColor),
              ),
            ),
            const SizedBox(width: 10),
            // Thông tin
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['hoTen']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u['tenDangNhap']?.toString() ?? '',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u['email']?.toString() ?? 'Chưa có email',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
            ),
            // Actions
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Badge trạng thái
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.4)
                        : themeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    size: 10,
                    color: isActive ? Colors.green : themeColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isActive ? 'Active' : 'Khóa',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.green : themeColor),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              // Nút action
              Row(mainAxisSize: MainAxisSize.min, children: [
                _iconBtn(Icons.edit_outlined, const Color(0xFF6C63FF),
                    () => _showEditDialog(u)),
                _iconBtn(
                  isActive
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  isActive ? Colors.orange : Colors.green,
                  () => _showBanDialog(u),
                ),
                if (isActive)
                  _iconBtn(Icons.delete_outline_rounded, Colors.red,
                      () => _softDelete(u)),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: onTap,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      );

  Widget _buildList(int role) {
    final users = _usersByRole[role] ?? [];
    if (users.isEmpty) {
      return const Center(child: Text('Không có tài khoản nào.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: users.length,
      itemBuilder: (_, i) => _buildUserCard(users[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('👥 Quản lý Tài khoản',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded)),
          IconButton(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: [
            Tab(text: 'Khách hàng (${_usersByRole[1]?.length ?? 0})'),
            Tab(text: 'Nhân viên (${_usersByRole[2]?.length ?? 0})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(1),
                _buildList(2),
              ],
            ),
    );
  }
}

// ── Widget option khóa ────────────────────────────────────────────────
class _BanOption extends StatelessWidget {
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _BanOption({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<bool>(
                value: true,
                groupValue: selected,
                activeColor: color,
                onChanged: (_) => onTap(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Expanded(child: child),
            ]),
      ),
    );
  }
}
