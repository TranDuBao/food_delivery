import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'group_cart_model.dart';
import 'group_model.dart';
import '../more/my_order_view.dart';
import '../more/sepay_payment_view.dart';

class GroupCartSheet extends StatefulWidget {
  final GroupModel group;
  final List<GroupCartItem> cart;
  final double discount;
  final String myId;
  final bool isAdmin;
  final VoidCallback onCartChanged;
  final void Function(List<GroupCartItem> items, double total, double discount)? onCheckoutSuccess;

  const GroupCartSheet({
    super.key,
    required this.group,
    required this.cart,
    required this.discount,
    required this.myId,
    required this.isAdmin,
    required this.onCartChanged,
    this.onCheckoutSuccess,
  });

  @override
  State<GroupCartSheet> createState() => _GroupCartSheetState();
}

class _GroupCartSheetState extends State<GroupCartSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<GroupCartItem> _cart;
  bool _checkingOut = false;
  String _paymentMethod = 'cash'; // 'sepay' | 'cash'

  int? _maToaNha;
  int? _maPhong;
  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _cart = List.from(widget.cart);
    _loadBuildings();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAddress, isToken: true);
      final data = res is Map ? res['data'] as Map<String, dynamic>? ?? {} : {};
      final list = data['buildings'] as List? ?? [];
      setState(() => _buildings =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  Future<void> _loadRooms(int maToaNha) async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAddress, isToken: true);
      final data = res is Map ? res['data'] as Map<String, dynamic>? ?? {} : {};
      final allRooms = data['rooms'] as List? ?? [];
      setState(() => _rooms = allRooms
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) => (r['maToaNha'] as num?)?.toInt() == maToaNha)
          .toList());
    } catch (_) {}
  }

  // ── Thay đổi số lượng ───────────────────────────────────────────────────────
  Future<void> _changeQty(GroupCartItem item, int delta) async {
    if (item.maTaiKhoan.toString() != widget.myId) {
      AppNotification.show(context,
          message: 'Chỉ chỉnh sửa được món của bạn', type: NotifType.error);
      return;
    }
    final newQty = item.soLuong + delta;
    if (newQty <= 0) {
      await _removeItem(item);
      return;
    }
    try {
      await ServiceCall.fetchPost(SVKey.svGroupCartUpdate, body: {
        'maGioHangNhom': item.maGioHangNhom,
        'soLuong': newQty,
      }, isToken: true);
      setState(() {
        final idx =
            _cart.indexWhere((i) => i.maGioHangNhom == item.maGioHangNhom);
        if (idx != -1) {
          _cart[idx] = GroupCartItem(
            maGioHangNhom: item.maGioHangNhom,
            maNhom: item.maNhom,
            maTaiKhoan: item.maTaiKhoan,
            maMonAn: item.maMonAn,
            soLuong: newQty,
            ghiChu: item.ghiChu,
            tenMonAn: item.tenMonAn,
            giaTien: item.giaTien,
            hinhAnh: item.hinhAnh,
            maGianHang: item.maGianHang,
            tenGianHang: item.tenGianHang,
            tenNguoiThem: item.tenNguoiThem,
            anhNguoiThem: item.anhNguoiThem,
          );
        }
      });
      widget.onCartChanged();
    } catch (e) {
      if (mounted)
        AppNotification.show(context,
            message: e.toString(), type: NotifType.error);
    }
  }

  Future<void> _removeItem(GroupCartItem item) async {
    if (item.maTaiKhoan.toString() != widget.myId) {
      AppNotification.show(context,
          message: 'Chỉ xoá được món của bạn', type: NotifType.error);
      return;
    }
    try {
      await ServiceCall.fetchPost(SVKey.svGroupCartRemove,
          body: {'maGioHangNhom': item.maGioHangNhom}, isToken: true);
      setState(() =>
          _cart.removeWhere((i) => i.maGioHangNhom == item.maGioHangNhom));
      widget.onCartChanged();
    } catch (e) {
      if (mounted)
        AppNotification.show(context,
            message: e.toString(), type: NotifType.error);
    }
  }

  Future<void> _checkout() async {
    if (_maToaNha == null || _maPhong == null) {
      AppNotification.show(context,
          message: 'Vui lòng chọn tòa nhà và phòng giao hàng',
          type: NotifType.error);
      return;
    }
    if (_cart.isEmpty) {
      AppNotification.show(context,
          message: 'Giỏ hàng nhóm đang trống', type: NotifType.error);
      return;
    }
    final uniqueMembers = _cart.map((i) => i.maTaiKhoan).toSet().length;
    if (uniqueMembers < 1) {
      AppNotification.show(context,
          message: 'Cần ít nhất 1 thành viên đặt món!',
          type: NotifType.error);
      return;
    }

    setState(() => _checkingOut = true);
    try {
      final res = await ServiceCall.fetchPost(SVKey.svGroupCheckout, body: {
        'groupId': widget.group.id,
        'maToaNha': _maToaNha,
        'maPhong': _maPhong,
        'phuongThucThanhToan': _paymentMethod == 'sepay' ? 'SePay' : 'COD',
      }, isToken: true);

      if (res['success'] == true) {
        // Backend trả về { orders: [...], message: "..." } — data là Map
        final data = res['data'];
        final orders = (data is Map ? data['orders'] : data) as List? ?? [];

        // Gửi thông báo tóm tắt vào group chat
        final cartSnapshot = List<GroupCartItem>.from(_cart);
        final totalSnapshot = _total;
        final discountSnapshot = _currentDiscount;
        widget.onCheckoutSuccess?.call(cartSnapshot, totalSnapshot, discountSnapshot);

        setState(() => _cart.clear());
        widget.onCartChanged();

        if (!mounted) return;
        Navigator.pop(context); // Đóng bottom sheet

        if (_paymentMethod == 'sepay' && orders.isNotEmpty) {
          // Lấy maDonHang của người dùng hiện tại (người tạo đơn)
          final myOrderMap = orders.firstWhere(
            (o) => o['maTaiKhoan']?.toString() == widget.myId,
            orElse: () => orders.first,
          ) as Map;
          final maDonHang = (myOrderMap['maDonHang'] as num?)?.toInt() ?? 0;
          final tongTien = totalSnapshot;

          // Gọi API tạo mã thanh toán SePay
          final payRes = await ServiceCall.fetchPost(
            SVKey.svPaymentCreate,
            isToken: true,
            body: {'maDonHang': maDonHang, 'tongTien': tongTien.round()},
          );

          if (!mounted) return;
          if (payRes is Map && payRes['success'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SepayPaymentView(
                  maDonHang: maDonHang,
                  amount: tongTien,
                  paymentCode: payRes['paymentCode']?.toString() ?? '',
                  qrUrl: payRes['qrUrl']?.toString() ?? '',
                  accountNumber: payRes['accountNumber']?.toString() ?? '',
                  accountName: payRes['accountName']?.toString() ?? '',
                  bankCode: payRes['bankCode']?.toString() ?? '',
                ),
              ),
            );
          } else {
            // Fallback nếu tạo QR thất bại
            AppNotification.show(context,
                message: 'Đặt hàng thành công! Tạo ${orders.length} đơn 🎉',
                type: NotifType.success);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrderHistoryView(
                  initialFilter: 'choGhepDon', isPushed: true,
                )));
          }
        } else {
          // Tiền mặt — chuyển tới trang đơn hàng để theo dõi & hủy
          AppNotification.show(context,
              message: 'Đặt hàng thành công! Tạo ${orders.length} đơn 🎉',
              type: NotifType.success);
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderHistoryView(
                initialFilter: 'choGhepDon', isPushed: true,
              )));
        }
      } else {
        throw Exception(res['message'] ?? 'Lỗi đặt hàng');
      }
    } catch (e) {
      if (mounted)
        AppNotification.show(context,
            message: e.toString(), type: NotifType.error);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  double get _subtotal => _cart.fold(0, (s, i) => s + i.tongTien);
  double get _discountAmount => _subtotal * _currentDiscount;
  double get _total => _subtotal - _discountAmount;

  // Tính discount theo số thành viên
  double get _currentDiscount {
    final n = _cart.map((i) => i.maTaiKhoan).toSet().length;
    if (n >= 10) return 0.10;
    if (n >= 7) return 0.08;
    if (n >= 5) return 0.05;
    if (n >= 3) return 0.03;
    return 0;
  }

  Map<String, List<GroupCartItem>> get _byUser {
    final map = <String, List<GroupCartItem>>{};
    for (final item in _cart) {
      final key = '${item.maTaiKhoan}__${item.tenNguoiThem}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.92;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle bar
        Center(
            child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Icon(Icons.shopping_basket_rounded, color: TColor.primary),
            const SizedBox(width: 8),
            Text('Giỏ hàng nhóm',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryText)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_cart.length} món',
                  style: TextStyle(
                      color: TColor.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ),
        // Member progress + discount
        _buildMemberProgress(),
        // Discount banner (khi đã có giảm giá)
        if (_currentDiscount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  TColor.primary.withValues(alpha: 0.85),
                  TColor.primary
                ]),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                  'Đang giảm ${(_currentDiscount * 100).toInt()}% cho nhóm!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              Text('-${_discountAmount.toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ]),
          ),
        // Tabs
        TabBar(
          controller: _tab,
          labelColor: TColor.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: TColor.primary,
          tabs: const [
            Tab(text: 'Theo thành viên'),
            Tab(text: 'Tất cả món')
          ],
        ),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            _buildByUserTab(),
            _buildAllItemsTab(),
          ]),
        ),
        // Checkout panel — tất cả thành viên đều thấy và bấm được
        _buildCheckoutPanel(),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Thanh tiến trình thành viên + badge giảm giá ──────────────────────────
  Widget _buildMemberProgress() {
    final uniqueMembers = _cart.map((i) => i.maTaiKhoan).toSet().length;
    final totalMembers = widget.group.members.length;

    // Badge giảm giá hiện tại
    String discountLabel = '';
    if (uniqueMembers >= 10) discountLabel = 'Giảm 10%! 🎉';
    else if (uniqueMembers >= 7) discountLabel = 'Giảm 8%! 🎊';
    else if (uniqueMembers >= 5) discountLabel = 'Giảm 5%! 🎁';
    else if (uniqueMembers >= 3) discountLabel = 'Giảm 3%';

    // Gợi ý mốc tiếp theo
    String nextHint = '';
    if (uniqueMembers < 3) nextHint = 'Thêm ${3 - uniqueMembers} người nữa để đặt được';
    else if (uniqueMembers < 5) nextHint = 'Thêm ${5 - uniqueMembers} người → giảm 5%';
    else if (uniqueMembers < 7) nextHint = 'Thêm ${7 - uniqueMembers} người → giảm 8%';
    else if (uniqueMembers < 10) nextHint = 'Thêm ${10 - uniqueMembers} người → giảm 10%';

    // Màu progress bar
    Color barColor = uniqueMembers >= 5
        ? TColor.primary
        : uniqueMembers >= 3
            ? Colors.green
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
          ]),
      child: Row(children: [
        Icon(Icons.people_rounded,
            color: uniqueMembers >= 3 ? TColor.primary : Colors.orange,
            size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Flexible(
                child: Text(
                  '$uniqueMembers/${totalMembers > 0 ? totalMembers : "?"} thành viên đã đặt',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: uniqueMembers >= 3
                          ? TColor.primaryText
                          : Colors.orange.shade700),
                ),
              ),
              if (discountLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: TColor.primary,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(discountLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            if (nextHint.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(nextHint,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalMembers > 0 ? uniqueMembers / totalMembers : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 5,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Tab theo thành viên ────────────────────────────────────────────────────
  Widget _buildByUserTab() {
    if (_cart.isEmpty) return _empty();
    final entries = _byUser.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final parts = entry.key.split('__');
        final name = parts.length > 1 ? parts[1] : 'Thành viên';
        final items = entry.value;
        final userTotal = items.fold(0.0, (s, it) => s + it.tongTien);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6)
              ]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(children: [
                CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        TColor.primary.withValues(alpha: 0.15),
                    child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: TColor.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
                const SizedBox(width: 8),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text('${userTotal.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(
                        color: TColor.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
            const Divider(height: 1),
            ...items.map((item) => _ItemRow(
                  item: item,
                  myId: widget.myId,
                  onRemove: () => _removeItem(item),
                  onQtyChanged: (delta) => _changeQty(item, delta),
                )),
          ]),
        );
      },
    );
  }

  // ── Tab tất cả món ─────────────────────────────────────────────────────────
  Widget _buildAllItemsTab() {
    if (_cart.isEmpty) return _empty();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cart.length,
      itemBuilder: (_, i) => _ItemRow(
        item: _cart[i],
        myId: widget.myId,
        onRemove: () => _removeItem(_cart[i]),
        onQtyChanged: (delta) => _changeQty(_cart[i], delta),
      ),
    );
  }

  Widget _empty() => const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.black12),
        SizedBox(height: 12),
        Text('Chưa có món nào', style: TextStyle(color: Colors.grey)),
      ]));

  GroupCartItem? get _firstCreatorItem {
    if (_cart.isEmpty) return null;
    GroupCartItem? firstItem;
    for (final item in _cart) {
      if (item.thoiGianThem == null) continue;
      if (firstItem == null || item.thoiGianThem!.isBefore(firstItem.thoiGianThem!)) {
        firstItem = item;
      }
    }
    if (firstItem == null) {
      for (final item in _cart) {
        if (firstItem == null || item.maGioHangNhom < firstItem.maGioHangNhom) {
          firstItem = item;
        }
      }
    }
    return firstItem;
  }

  // ── Checkout panel (tất cả đều thấy) ──────────────────────────────────────
  Widget _buildCheckoutPanel() {
    final uniqueMembers = _cart.map((i) => i.maTaiKhoan).toSet().length;
    final creator = _firstCreatorItem;
    final isCreator = creator == null || creator.maTaiKhoan.toString() == widget.myId;
    final canCheckout = uniqueMembers >= 1 && _cart.isNotEmpty && isCreator; // TEST MODE: min 1

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Địa chỉ giao hàng — Chỉ hiển thị & cho phép nhập với người tạo đơn
        if (isCreator && creator != null) ...[
          const Text('Địa chỉ giao hàng',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<int>(
              value: _maToaNha,
              decoration: InputDecoration(
                  labelText: 'Tòa nhà',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true),
              items: _buildings.map((b) {
                final id = (b['maToaNha'] as num?)?.toInt() ?? 0;
                return DropdownMenuItem(
                    value: id, child: Text(b['tenToaNha']?.toString() ?? ''));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _maToaNha = v;
                  _maPhong = null;
                  _rooms = [];
                });
                if (v != null) _loadRooms(v);
              },
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<int>(
              value: _maPhong,
              decoration: InputDecoration(
                  labelText: 'Phòng',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true),
              items: _rooms.map((r) {
                final id = (r['maPhong'] as num?)?.toInt() ?? 0;
                return DropdownMenuItem(
                    value: id, child: Text(r['tenPhong']?.toString() ?? ''));
              }).toList(),
              onChanged: (v) => setState(() => _maPhong = v),
            )),
          ]),
          const SizedBox(height: 10),
        ],
        // ── Phương thức thanh toán ───────────────────────────────────────────
        if (isCreator && creator != null) ...[
          const Text('Phương thức thanh toán',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: [
              _paymentTile('sepay', 'Chuyển khoản QR (SePay)',
                  Icons.qr_code_scanner_rounded, const Color(0xFF0D7EFF)),
              Divider(height: 1, color: Colors.grey.shade200),
              _paymentTile('cash', 'Tiền mặt khi nhận hàng',
                  Icons.payments_rounded, Colors.green.shade600),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        // Tổng tiền + nút đặt
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng cộng',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text('${_total.toStringAsFixed(0)} VNĐ',
                style: TextStyle(
                    color: TColor.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isCreator
                  ? ElevatedButton.icon(
                      onPressed: (_checkingOut || !canCheckout) ? null : _checkout,
                      icon: _checkingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.rocket_launch_rounded, size: 16),
                      label: Text(_checkingOut ? 'Đang đặt...' : 'Đặt hàng nhóm'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canCheckout ? TColor.primary : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200)),
                      child: Text(
                          'Chờ ${creator.tenNguoiThem} đặt hàng',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ]),
        // Hint khi chưa đủ 3 người (chỉ hiển thị cho người tạo đơn để nhắc nhở)
        if (isCreator && !canCheckout && _cart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Cần ít nhất 1 thành viên để checkout (TEST MODE)',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
            ),
          ),
      ]),
    );
  }

  Widget _paymentTile(String id, String title, IconData icon, Color color) {
    final isSelected = _paymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: isSelected ? TColor.primary : Colors.grey.shade300,
            size: 20,
          ),
        ]),
      ),
    );
  }
}

// ── Item row với nút tăng/giảm số lượng ────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final GroupCartItem item;
  final String myId;
  final VoidCallback onRemove;
  final void Function(int delta) onQtyChanged;

  const _ItemRow({
    required this.item,
    required this.myId,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = item.maTaiKhoan.toString() == myId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        // Ảnh món
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.hinhAnh != null && item.hinhAnh!.isNotEmpty
              ? Image.network(
                  item.hinhAnh!.startsWith('http')
                      ? item.hinhAnh!
                      : 'http://10.0.2.2:3001${item.hinhAnh}',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        const SizedBox(width: 10),
        // Tên & giá
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(item.tenMonAn,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${item.giaTien.toStringAsFixed(0)} VNĐ',
              style: TextStyle(
                  color: TColor.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ])),
        // Nút − / số lượng / + (chỉ món của mình)
        if (isOwn)
          Row(mainAxisSize: MainAxisSize.min, children: [
            _QtyBtn(
              icon: Icons.remove_rounded,
              onTap: () => onQtyChanged(-1),
              color: item.soLuong <= 1 ? Colors.red : Colors.grey.shade600,
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text('${item.soLuong}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            _QtyBtn(
              icon: Icons.add_rounded,
              onTap: () => onQtyChanged(1),
              color: TColor.primary,
            ),
          ])
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('x${item.soLuong}',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
      ]),
    );
  }

  Widget _placeholder() => Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10)),
      child:
          Icon(Icons.fastfood_rounded, color: Colors.grey.shade400, size: 22));
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QtyBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
