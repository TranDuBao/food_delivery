import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../more/my_order_view.dart';
import 'my_reviews_view.dart';
import 'personal_wallet_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _picker = ImagePicker();
  XFile? _image;
  Uint8List? _avatarBytes;

  String _name = '', _email = '', _mobile = '', _avatarUrl = '';
  int _totalOrders = 0;
  double _totalSpent = 0;
  List<Map<String,dynamic>> _monthly = [];

  @override void initState() { super.initState(); _loadLocal(); _fetchProfile(); _fetchStats(); }

  void _loadLocal() {
    final p = ServiceCall.userPayload;
    _name      = (p['fullName'] ?? p['name'] ?? '').toString().trim();
    _email     = (p['email'] ?? '').toString().trim();
    _mobile    = (p['mobile'] ?? p['phone'] ?? '').toString().trim();
    _avatarUrl = (p['avatarUrl'] ?? '').toString().trim();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerProfile, isToken: true);
      if (res != null && res['success'] == true) {
        final n = Map<String,dynamic>.from(ServiceCall.userPayload)
          ..addAll(Map<String,dynamic>.from(res['data'] as Map));
        ServiceCall.userPayload = n; Globs.udSet(n, Globs.userPayload);
        if (mounted) setState(_loadLocal);
      }
    } catch (_) {}
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerStats, isToken: true);
      if (res is Map && res['success'] == true) {
        final d = res['data'] as Map;
        final list = (d['monthly'] as List? ?? []);
        if (mounted) setState(() {
          _totalOrders = (d['tongDonHang'] as num?)?.toInt() ?? 0;
          _totalSpent  = double.tryParse(d['tongChiTieu']?.toString() ?? '0') ?? 0;
          _monthly = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
        });
      }
    } catch (_) {}
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final p = await _picker.pickImage(source: ImageSource.gallery); if (p == null) return;
    final bytes = await p.readAsBytes();
    setState(() { _image = p; _avatarBytes = bytes; });
    final token = Globs.udValueString(KKey.authToken); if (token.isEmpty) return;
    try {
      Globs.showHUD(status: 'Đang tải ảnh...');
      final req = http.MultipartRequest('POST', Uri.parse(SVKey.svCustomerProfileAvatar))
        ..headers['Authorization'] = 'Bearer $token';
      final media = _resolveMedia(p.mimeType);
      if (kIsWeb) req.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: p.name, contentType: media));
      else req.files.add(await http.MultipartFile.fromPath('avatar', p.path, contentType: media));
      final st = await req.send();
      final body = await st.stream.bytesToString();
      final dec = body.isNotEmpty ? json.decode(body) : {};
      if (st.statusCode >= 200 && st.statusCode < 300 && dec is Map) {
        final n = Map<String,dynamic>.from(ServiceCall.userPayload)..['avatarUrl'] = (dec['avatarUrl'] ?? '').toString();
        ServiceCall.userPayload = n; Globs.udSet(n, Globs.userPayload);
        if (mounted) { setState(() { _avatarBytes = null; _image = null; _loadLocal(); }); _snack('Cập nhật ảnh thành công!'); }
      }
    } catch (e) { if (mounted) _snack(e.toString(), err: true); }
    finally { Globs.hideHUD(); }
  }

  MediaType _resolveMedia(String? m) {
    final s = (m ?? '').toLowerCase(); if (s.startsWith('image/')) { final p = s.split('/'); if (p.length == 2) return MediaType('image', p[1]); } return MediaType('image', 'jpeg');
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: err ? Colors.red : TColor.primary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  // ── Edit Profile Dialog ────────────────────────────────────────────────────
  void _openEdit() {
    final nc = TextEditingController(text: _name);
    final ec = TextEditingController(text: _email);
    final mc = TextEditingController(text: _mobile);
    showDialog(context: context, builder: (_) => _CenterDialog(
      title: 'Thay đổi thông tin',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(nc, 'Họ và tên *', Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _field(ec, 'Email', Icons.mail_outline_rounded, type: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _field(mc, 'Số điện thoại', Icons.phone_android_rounded, type: TextInputType.phone),
      ]),
      submitLabel: 'Lưu thay đổi',
      submitColor: TColor.primary,
      onSubmit: () async {
        final name = nc.text.trim();
        if (name.isEmpty) { _snack('Họ tên là bắt buộc!', err: true); return; }
        try {
          Globs.showHUD();
          await ServiceCall.fetchPut(SVKey.svCustomerProfile, isToken: true,
            body: {'hoTen': name, 'email': ec.text.trim(), 'soDienThoai': mc.text.trim()});
          final n = Map<String,dynamic>.from(ServiceCall.userPayload)
            ..['fullName'] = name ..[KKey.name] = name ..['email'] = ec.text.trim() ..['phone'] = mc.text.trim() ..['mobile'] = mc.text.trim();
          ServiceCall.userPayload = n; Globs.udSet(n, Globs.userPayload);
          if (mounted) { setState(_loadLocal); Navigator.pop(context); _snack('Cập nhật thành công!'); }
        } catch (e) { if (mounted) _snack(e.toString(), err: true); }
        finally { Globs.hideHUD(); }
      },
    ));
  }

  // ── Change Password Dialog ─────────────────────────────────────────────────
  void _openChangePw() => showDialog(context: context, builder: (_) => _ChangePasswordDialog(
    onSave: (old, newP) async {
      try {
        Globs.showHUD();
        await ServiceCall.fetchPut(SVKey.svCustomerChangePassword, isToken: true, body: {'oldPassword': old, 'newPassword': newP});
        if (mounted) { Navigator.pop(context); _snack('Đổi mật khẩu thành công!'); }
      } catch (e) { if (mounted) _snack(e.toString(), err: true); }
      finally { Globs.hideHUD(); }
    },
  ));

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Bạn có chắc muốn đăng xuất không?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy', style: TextStyle(color: TColor.secondaryText))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
      ],
    ));
    if (ok == true) ServiceCall.logout();
  }

  // ── Avatar widget ──────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    Widget img;
    if (_avatarBytes != null) img = Image.memory(_avatarBytes!, fit: BoxFit.cover);
    else if (_image != null && !kIsWeb) img = Image.file(File(_image!.path), fit: BoxFit.cover);
    else if (_avatarUrl.isNotEmpty) {
      final url = _avatarUrl.startsWith('http') ? _avatarUrl : '${SVKey.nodeUrl}$_avatarUrl';
      img = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 44, color: Colors.white70));
    } else img = const Icon(Icons.person_rounded, size: 44, color: Colors.white70);
    return GestureDetector(onTap: _pickAvatar,
      child: Stack(alignment: Alignment.bottomRight, children: [
        Container(width: 88, height: 88,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white24, border: Border.all(color: Colors.white, width: 3)),
          clipBehavior: Clip.antiAlias, child: ClipOval(child: img)),
        Container(padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(Icons.camera_alt_rounded, size: 13, color: TColor.primary)),
      ]));
  }

  String _fmt(double v) => '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(child: Column(children: [
        // ── Gradient Header ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [TColor.primary, const Color(0xFFFF8C42)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(children: [
              _buildAvatar(),
              const SizedBox(height: 10),
              Text(_name.isEmpty ? 'Người dùng' : _name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              if (_email.isNotEmpty) Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_mobile.isNotEmpty) Text(_mobile, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          )),
        ),

        // ── Stats Row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: _StatCard(label: 'Đơn đã giao', value: '$_totalOrders', icon: Icons.receipt_long_rounded, color: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Tổng chi tiêu', value: _fmt(_totalSpent), icon: Icons.payments_rounded, color: const Color(0xFF00C853))),
          ]),
        ),

        // ── Monthly chart ─────────────────────────────────────────────────
        if (_monthly.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0,3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Chi tiêu theo tháng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 14),
              _SpendingChart(monthly: _monthly),
            ])),
        ],

        const SizedBox(height: 16),

        // ── Section: Tài khoản ────────────────────────────────────────────
        _sectionLabel('Tài khoản cá nhân'),
        _menuCard([
          _tile(Icons.manage_accounts_rounded, TColor.primary, 'Thay đổi thông tin', 'Tên, email, số điện thoại', _openEdit),
          _div(),
          _tile(Icons.lock_outline_rounded, Colors.indigo, 'Đổi mật khẩu', 'Cập nhật mật khẩu đăng nhập', _openChangePw),
        ]),
        const SizedBox(height: 16),

        // ── Section: Hoạt động ────────────────────────────────────────────
        _sectionLabel('Hoạt động'),
        _menuCard([
          _tile(Icons.receipt_long_rounded, Colors.orange, 'Lịch sử mua hàng', 'Xem các đơn hàng đã đặt',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryView()))),
          _div(),

          _tile(Icons.star_rounded, const Color(0xFFFFC107), 'Đánh giá của tôi', 'Xem các món đã bình luận',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsView()))),
        ]),
        const SizedBox(height: 24),

        // ── Sign Out ──────────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade200)))))),
        const SizedBox(height: 32),
      ])),
    );
  }

  Widget _sectionLabel(String l) => Padding(padding: const EdgeInsets.fromLTRB(20,0,20,8),
    child: Align(alignment: Alignment.centerLeft,
      child: Text(l, style: TextStyle(color: TColor.secondaryText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))));

  Widget _menuCard(List<Widget> c) => Container(margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0,3))]),
    child: Column(children: c));

  Widget _tile(IconData icon, Color color, String label, String sub, VoidCallback onTap) =>
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: TColor.primaryText, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(sub, style: TextStyle(color: TColor.secondaryText, fontSize: 11)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
        ])));

  Widget _div() => Divider(height: 1, indent: 70, endIndent: 16, color: Colors.grey.shade100);

  TextField _field(TextEditingController c, String label, IconData icon, {TextInputType? type}) =>
    TextField(controller: c, keyboardType: type, decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)));
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0,2))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]));
}

// ─── Spending Chart ───────────────────────────────────────────────────────────
class _SpendingChart extends StatelessWidget {
  final List<Map<String,dynamic>> monthly;
  const _SpendingChart({required this.monthly});
  @override Widget build(BuildContext context) {
    final maxV = monthly.fold<double>(1, (m, e) => max(m, double.tryParse(e['tongTien']?.toString() ?? '0') ?? 0));
    return Column(children: [
      SizedBox(height: 80,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: monthly.map((m) {
          final v = double.tryParse(m['tongTien']?.toString() ?? '0') ?? 0;
          final ratio = maxV > 0 ? v / maxV : 0.0;
          return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(height: 60 * ratio + 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [TColor.primary, const Color(0xFFFF8C42)],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  borderRadius: BorderRadius.circular(6))),
            ])));
        }).toList())),
      const SizedBox(height: 6),
      Row(children: monthly.map((m) => Expanded(
        child: Text(m['label']?.toString().split('/').first ?? '', textAlign: TextAlign.center,
          style: TextStyle(color: TColor.secondaryText, fontSize: 9)))).toList()),
    ]);
  }
}

// ─── Generic centered dialog ──────────────────────────────────────────────────
class _CenterDialog extends StatelessWidget {
  final String title; final Widget child; final String submitLabel;
  final Color submitColor; final VoidCallback onSubmit;
  const _CenterDialog({required this.title, required this.child, required this.submitLabel, required this.submitColor, required this.onSubmit});
  @override Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ]),
      const SizedBox(height: 16),
      child,
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50,
        child: ElevatedButton(onPressed: onSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: submitColor, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: Text(submitLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
    ])));
}

// ─── Change Password Dialog ───────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String, String) onSave;
  const _ChangePasswordDialog({required this.onSave});
  @override State<_ChangePasswordDialog> createState() => _ChangePwState();
}
class _ChangePwState extends State<_ChangePasswordDialog> {
  final _o = TextEditingController(), _n = TextEditingController(), _c = TextEditingController();
  bool _so = false, _sn = false, _sc = false;
  @override void dispose() { _o.dispose(); _n.dispose(); _c.dispose(); super.dispose(); }

  void _submit() {
    if (_o.text.isEmpty || _n.text.isEmpty || _c.text.isEmpty) { _snack('Vui lòng điền đầy đủ!'); return; }
    if (_n.text.length < 6) { _snack('Mật khẩu mới ít nhất 6 ký tự!'); return; }
    if (_n.text != _c.text) { _snack('Mật khẩu xác nhận không khớp!'); return; }
    widget.onSave(_o.text, _n.text);
  }
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));

  InputDecoration _dec(String l, bool show, VoidCallback toggle) => InputDecoration(
    labelText: l, prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
    suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: toggle),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14));

  @override Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        const Expanded(child: Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ]),
      const SizedBox(height: 16),
      TextField(controller: _o, obscureText: !_so, decoration: _dec('Mật khẩu hiện tại', _so, () => setState(() => _so = !_so))),
      const SizedBox(height: 10),
      TextField(controller: _n, obscureText: !_sn, decoration: _dec('Mật khẩu mới', _sn, () => setState(() => _sn = !_sn))),
      const SizedBox(height: 10),
      TextField(controller: _c, obscureText: !_sc, decoration: _dec('Xác nhận mật khẩu mới', _sc, () => setState(() => _sc = !_sc)),
        onSubmitted: (_) => _submit()),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50,
        child: ElevatedButton(onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: const Text('Đổi mật khẩu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
    ])));
}