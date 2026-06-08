import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'chat_service.dart';
import 'group_cart_model.dart';
import 'group_cart_sheet.dart';
import 'group_model.dart';

class GroupOrderView extends StatefulWidget {
  final GroupModel group;
  final String myId;
  final String myName;
  final bool isAdmin;
  const GroupOrderView({super.key, required this.group, required this.myId, required this.myName, required this.isAdmin});

  @override
  State<GroupOrderView> createState() => _GroupOrderViewState();
}

class _GroupOrderViewState extends State<GroupOrderView> {
  List<Map<String, dynamic>> _canteens = [];
  List<Map<String, dynamic>> _dishes = [];
  List<GroupCartItem> _cart = [];
  double _discount = 0;
  bool _loadingCanteens = true;
  bool _loadingDishes = false;
  int? _selectedCanteenId;
  String _selectedCanteenName = '';
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCanteens();
    _loadCart();
  }

  // Trả lời chào theo giờ
  String _getMealGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return 'buổi sáng ngon miệng';
    if (h >= 10 && h < 14) return 'bữa trưa ngon miệng';
    if (h >= 14 && h < 17) return 'bữa xế ngon';
    return 'buổi tối ngon miệng';
  }

  // Gửi system message vào chat nhóm
  Future<void> _sendGroupSystemMessage(String senderName, String dishName) async {
    final greeting = _getMealGreeting();
    final msg = GroupMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'Hệ thống',
      text: '🍽️ $senderName đã đặt món "$dishName" vào giỏ hàng nhóm!\n'
          '👉 Hãy đặt cùng để cùng nhau thưởng thức $greeting nhé! 😋',
      timestamp: DateTime.now(),
      seenBy: [],
    );
    await ChatService.instance.appendMessage(widget.group.id, msg);
  }

  Future<void> _loadCanteens() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCanteens, isToken: true);
      final list = (res is Map ? res['data'] ?? [] : res) as List? ?? [];
      setState(() {
        _canteens = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingCanteens = false;
      });
    } catch (_) {
      setState(() => _loadingCanteens = false);
    }
  }

  Future<void> _loadDishes(int canteenId, String canteenName) async {
    setState(() { _loadingDishes = true; _selectedCanteenId = canteenId; _selectedCanteenName = canteenName; });
    try {
      final res = await ServiceCall.fetchGet(SVKey.svDishesByCanteen(canteenId), isToken: true);
      final list = (res is Map ? res['data'] ?? [] : res) as List? ?? [];
      setState(() {
        _dishes = list.map((e) => Map<String, dynamic>.from(e as Map))
            .where((d) => d['soLuongTon'] != 0)
            .toList();
        _loadingDishes = false;
      });
    } catch (_) {
      setState(() => _loadingDishes = false);
    }
  }

  Future<void> _loadCart() async {
    try {
      final res = await ServiceCall.fetchPost(
        SVKey.svGroupCart,
        body: {'groupId': widget.group.id},
        isToken: true,
      );
      if (kDebugMode) print('[GroupCart] response: $res');
      if (res is Map && res['success'] == true) {
        final list = res['data'] as List? ?? [];
        setState(() {
          _cart = list.map((e) => GroupCartItem.fromJson(e as Map<String, dynamic>)).toList();
          _discount = (res['discount'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      if (kDebugMode) print('[GroupCart] _loadCart error: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> dish) async {
    // API trả về id (món ăn), không phải maMonAn
    final maMonAn = (dish['id'] as num?)?.toInt();
    final tenMon = dish['name']?.toString() ?? dish['tenMonAn']?.toString() ?? '';
    if (maMonAn == null) return;
    try {
      await ServiceCall.fetchPost(SVKey.svGroupCartAdd, body: {
        'groupId': widget.group.id,
        'maMonAn': maMonAn,
        'soLuong': 1,
      }, isToken: true);
      await _loadCart();
      // Gửi system message vào chat nhóm
      await _sendGroupSystemMessage(widget.myName, tenMon);
      if (mounted) {
        AppNotification.show(context, message: 'Đã thêm $tenMon vào giỏ nhóm 🛒', type: NotifType.success);
      }
    } catch (e) {
      if (mounted) AppNotification.show(context, message: e.toString(), type: NotifType.error);
    }
  }

  int _myCartCount() => _cart.where((i) => i.maTaiKhoan.toString() == widget.myId).fold(0, (s, i) => s + i.soLuong);

  void _openCart() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupCartSheet(
        group: widget.group,
        cart: _cart,
        discount: _discount,
        myId: widget.myId,
        isAdmin: widget.isAdmin,
        onCartChanged: _loadCart,
        onCheckoutSuccess: (items, total, discount) =>
            _sendCheckoutSystemMessage(items, total, discount),
      ),
    );
    await _loadCart();
  }

  /// Gửi thông báo tổng kết đơn vào group chat sau khi checkout thành công
  Future<void> _sendCheckoutSystemMessage(
      List<GroupCartItem> items, double total, double discount) async {
    // Nhóm theo tên người đặt
    final byUser = <String, List<GroupCartItem>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.tenNguoiThem, () => []).add(item);
    }
    final sb = StringBuffer();
    sb.writeln('🎉 Đơn hàng nhóm đã được đặt thành công!');
    sb.writeln('');
    for (final entry in byUser.entries) {
      final name = entry.key;
      final userItems = entry.value;
      final userTotal =
          userItems.fold(0.0, (s, i) => s + i.tongTien);
      sb.writeln('👤 $name: ${userTotal.toStringAsFixed(0)} VNĐ');
      for (final i in userItems) {
        sb.writeln('   • ${i.tenMonAn} x${i.soLuong}');
      }
    }
    if (discount > 0) {
      sb.writeln('');
      sb.writeln('🏷️ Giảm giá: -${(total * discount / (1 - discount)).toStringAsFixed(0)} VNĐ');
    }
    sb.writeln('');
    sb.writeln('💰 Tổng cộng: ${total.toStringAsFixed(0)} VNĐ');
    sb.writeln('📦 Đang chuẩn bị — hãy chú ý điện thoại nhé!');

    final msg = GroupMessage(
      id: 'checkout_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'Hệ thống',
      text: sb.toString().trim(),
      timestamp: DateTime.now(),
      seenBy: [],
    );
    await ChatService.instance.appendMessage(widget.group.id, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Đặt món nhóm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: TColor.primaryText)),
          Text(widget.group.name, style: TextStyle(fontSize: 12, color: TColor.primary)),
        ]),
        actions: [
          Stack(alignment: Alignment.topRight, children: [
            IconButton(
              icon: Icon(Icons.shopping_cart_rounded, color: TColor.primary),
              onPressed: _openCart,
              tooltip: 'Giỏ hàng nhóm',
            ),
            if (_myCartCount() > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('${_myCartCount()}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                ),
              ),
          ]),
        ],
      ),
      body: Column(children: [
        // Discount banner
        if (_discount > 0)
          Container(
            width: double.infinity,
            color: TColor.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.local_offer_rounded, color: TColor.primary, size: 16),
              const SizedBox(width: 8),
              Text('Nhóm được giảm ${(_discount * 100).toInt()}% cho đơn này! 🎉',
                  style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        // Canteen list + dishes
        Expanded(child: _loadingCanteens
          ? const Center(child: CircularProgressIndicator())
          : _selectedCanteenId == null
            ? _buildCanteenList()
            : _buildDishList()),
      ]),
    );
  }

  Widget _buildCanteenList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Chọn quán ăn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: TColor.primaryText)),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: _canteens.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final c = _canteens[i];
            // API trả về: id, name, bannerUrl/logoUrl, location
            final id = (c['id'] as num?)?.toInt() ?? (c['maGianHang'] as num?)?.toInt() ?? 0;
            final name = c['name']?.toString() ?? c['tenGianHang']?.toString() ?? '';
            final banner = c['bannerUrl']?.toString() ?? c['logoUrl']?.toString() ?? c['banner']?.toString() ?? '';
            final desc = c['location']?.toString() ?? c['moTa']?.toString() ?? '';
            return InkWell(
              onTap: () => _loadDishes(id, name),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: banner.startsWith('http')
                      ? Image.network(banner, width: 90, height: 75, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _placeholder() => Container(width: 90, height: 75, color: Colors.grey.shade200,
    child: Icon(Icons.restaurant_rounded, color: Colors.grey.shade400, size: 28));

  Widget _buildDishList() {
    return Column(children: [
      // Back + canteen name
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => setState(() { _selectedCanteenId = null; _dishes = []; })),
          Text(_selectedCanteenName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
      Expanded(
        child: _loadingDishes
          ? const Center(child: CircularProgressIndicator())
          : _dishes.isEmpty
            ? const Center(child: Text('Chưa có món nào', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _dishes.length,
                itemBuilder: (_, i) => _DishCard(dish: _dishes[i], onAdd: () => _addToCart(_dishes[i])),
              ),
      ),
    ]);
  }
}

class _DishCard extends StatelessWidget {
  final Map<String, dynamic> dish;
  final VoidCallback onAdd;
  const _DishCard({required this.dish, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    // API trả về: id, name, price, imageUrl, description, rate...
    final name = dish['name']?.toString() ?? dish['tenMonAn']?.toString() ?? '';
    final price = (dish['price'] as num?)?.toDouble() ?? (dish['giaTien'] as num?)?.toDouble() ?? 0;
    final img = dish['imageUrl']?.toString() ?? dish['hinhAnh']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          child: img.isNotEmpty
            ? Image.network(img.startsWith('http') ? img : 'http://10.0.2.2:3001$img',
                width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
            : _ph(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${price.toStringAsFixed(0)} VNĐ', style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700, fontSize: 13)),
        ])),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            margin: const EdgeInsets.all(12),
            width: 32, height: 32,
            decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _ph() => Container(width: 80, height: 80, color: Colors.grey.shade100, child: Icon(Icons.fastfood_rounded, color: Colors.grey.shade400));
}
