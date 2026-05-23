import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/app_alert.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import 'staff_item_details_view.dart';
import 'staff_more_view.dart';
import 'staff_voucher_view.dart';

class StaffMenuView extends StatefulWidget {
  const StaffMenuView({super.key});

  @override
  State<StaffMenuView> createState() => _StaffMenuViewState();
}

class _StaffMenuViewState extends State<StaffMenuView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeMenu = [];
  List<Map<String, dynamic>> _deletedMenu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllMenus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMenus() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ServiceCall.fetchGet(SVKey.svStaffStoreMenu, isToken: true),
        ServiceCall.fetchGet(SVKey.svStaffMenuDeleted, isToken: true),
      ]);

      final activeData = results[0];
      final deletedData = results[1];

      setState(() {
        if (activeData is Map && activeData['data'] is List) {
          _activeMenu = (activeData['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (deletedData is Map && deletedData['data'] is List) {
          _deletedMenu = (deletedData['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      });
    } catch (e) {
      debugPrint('[StaffMenu] error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  String _formatPrice(dynamic v) {
    final val = _toDouble(v);
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  // ── Soft delete ──
  Future<void> _confirmDelete(Map<String, dynamic> dish) async {
    final name = dish['tenMonAn'] ?? dish['name'] ?? 'món ăn này';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ngừng bán món?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Món "$name" sẽ chuyển sang tab "Ngừng bán". Bạn có thể khôi phục bất cứ lúc nào.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngừng bán',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final id = dish['maMonAn'] ?? dish['id'];
        await ServiceCall.fetchDelete(SVKey.svStaffDeleteDish(id),
            isToken: true);
        await _loadAllMenus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã chuyển sang Ngừng bán.'),
                backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  // ── Restore ──
  Future<void> _restoreDish(Map<String, dynamic> dish) async {
    final name = dish['tenMonAn'] ?? dish['name'] ?? 'món ăn này';
    final ctrl = TextEditingController(text: '99');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nhập số lượng tồn',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang khôi phục món "$name". Vui lòng nhập số lượng tồn kho mới:'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final stock = int.tryParse(ctrl.text.trim()) ?? 0;
      try {
        final id = dish['maMonAn'] ?? dish['id'];
        await ServiceCall.fetchPut(SVKey.svStaffRestoreDish(id),
            isToken: true, body: {'soLuongTon': stock});
        await _loadAllMenus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã khôi phục món ăn!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  // ── Image picker & upload ──
  Future<String?> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return null;

    try {
      Globs.showHUD(status: 'Đang tải ảnh...');
      final url = await ServiceCall.uploadImageFile(
        SVKey.svStaffUploadDishImage,
        picked,
        fieldName: 'image',
      );
      Globs.hideHUD();
      return url;
    } catch (e) {
      Globs.hideHUD();
      debugPrint('Upload dish image error: $e');
      return null;
    }
  }

  // ── Dish editor sheet ──
  Future<void> _showDishEditor({Map<String, dynamic>? dish}) async {
    final isEdit = dish != null;
    final nameCtrl = TextEditingController(
        text: (dish?['tenMonAn'] ?? dish?['name'] ?? '').toString());
    final priceCtrl = TextEditingController(
        text: _toDouble(dish?['giaTien'] ?? dish?['price']).toStringAsFixed(0));
    final descCtrl = TextEditingController(
        text: (dish?['moTa'] ?? dish?['description'] ?? '').toString());
    final stockCtrl = TextEditingController(
        text: (dish?['soLuongTon'] ?? 99).toString());

    bool isAvailable = dish?['trangThai'] != 0 && dish?['isAvailable'] != false;
    String currentImageUrl =
        (dish?['hinhAnh'] ?? dish?['imageUrl'] ?? '').toString();
    File? localImageFile;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  isEdit ? 'Sửa món ăn' : 'Thêm món ăn',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Image picker ──
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                      maxWidth: 1200,
                    );
                    if (picked != null) {
                      setModal(() {
                        localImageFile = File(picked.path);
                        currentImageUrl = picked.path;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TColor.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: localImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(localImageFile!,
                                fit: BoxFit.cover, width: double.infinity),
                          )
                        : (currentImageUrl.isNotEmpty &&
                                currentImageUrl.startsWith('http'))
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.network(currentImageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholderWidget()),
                              )
                            : _imagePlaceholderWidget(),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1200,
                      );
                      if (picked != null) {
                        setModal(() {
                          localImageFile = File(picked.path);
                          currentImageUrl = picked.path;
                        });
                      }
                    },
                    icon: Icon(Icons.photo_library_rounded,
                        color: TColor.primary, size: 18),
                    label: Text(
                      localImageFile != null ? 'Đổi ảnh khác' : 'Chọn ảnh từ thư viện',
                      style: TextStyle(
                          color: TColor.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildField('Tên món', nameCtrl, hint: 'VD: Cơm Gà Xối Mỡ'),
                const SizedBox(height: 14),
                _buildField('Giá bán (đ)', priceCtrl,
                    hint: '35000', isNumber: true),
                const SizedBox(height: 14),
                _buildField('Mô tả', descCtrl,
                    hint: 'Mô tả ngắn về món ăn...', maxLines: 3),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số lượng tồn kho',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            int currentVal = int.tryParse(stockCtrl.text) ?? 0;
                            if (currentVal > 0) {
                              setModal(() {
                                int newVal = currentVal - 1;
                                stockCtrl.text = newVal.toString();
                                if (newVal <= 0) {
                                  isAvailable = false;
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: TColor.primary.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.remove, color: TColor.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (val) {
                              int v = int.tryParse(val) ?? 0;
                              if (v > 0 && !isAvailable) {
                                setModal(() => isAvailable = true);
                              } else if (v <= 0 && isAvailable) {
                                setModal(() => isAvailable = false);
                              }
                            },
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: '99',
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            int currentVal = int.tryParse(stockCtrl.text) ?? 0;
                            setModal(() {
                              int newVal = currentVal + 1;
                              stockCtrl.text = newVal.toString();
                              if (newVal > 0) {
                                isAvailable = true;
                              }
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: TColor.primary.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add, color: TColor.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Toggle availability
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text(
                      'Còn bán',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A)),
                    ),
                    subtitle: Text(
                      isAvailable ? 'Đang bán' : 'Hết món',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    value: isAvailable,
                    activeThumbColor: TColor.primary,
                    onChanged: (v) => setModal(() => isAvailable = v),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final price = double.tryParse(priceCtrl.text.trim());
                      final stock = int.tryParse(stockCtrl.text.trim()) ?? 99;
                      if (nameCtrl.text.trim().isEmpty ||
                          price == null ||
                          price <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Tên món và giá không hợp lệ.')),
                        );
                        return;
                      }

                      try {
                        // Upload ảnh nếu người dùng đã chọn file mới
                        String finalImageUrl = currentImageUrl;
                        if (localImageFile != null) {
                          Globs.showHUD(status: 'Đang tải ảnh...');
                          final uploaded = await ServiceCall.uploadImageFile(
                            SVKey.svStaffUploadDishImage,
                            XFile(localImageFile!.path),
                            fieldName: 'image',
                          );
                          Globs.hideHUD();
                          if (uploaded != null) {
                            finalImageUrl = uploaded;
                          }
                        }

                        final payload = {
                          'tenMonAn': nameCtrl.text.trim(),
                          'giaTien': price,
                          'moTa': descCtrl.text.trim(),
                          'hinhAnh': finalImageUrl.startsWith('http')
                              ? finalImageUrl
                              : (localImageFile != null ? '' : currentImageUrl),
                          'trangThai': isAvailable ? 1 : 0,
                          'soLuongTon': stock,
                        };

                        if (isEdit) {
                          final id = dish['maMonAn'] ?? dish['id'];
                          await ServiceCall.fetchPut(
                            SVKey.svStaffUpdateDish(id),
                            body: payload,
                            isToken: true,
                          );
                        } else {
                          await ServiceCall.fetchPost(
                            SVKey.svStaffCreateDish,
                            body: payload,
                            isToken: true,
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadAllMenus();
                      } catch (e) {
                        Globs.hideHUD();
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: Text(
                      isEdit ? 'Lưu thay đổi' : 'Thêm món',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholderWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 40, color: TColor.primary.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text('Nhấn để chọn ảnh',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String hint = '', bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quản lý thực đơn',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: TColor.primary),
          onSelected: (val) {
            if (val == 'store') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffMoreView()));
            } else if (val == 'voucher') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffVoucherView()));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'store', child: Row(children: [
              Icon(Icons.store_outlined, size: 18), SizedBox(width: 8), Text('Thông tin cửa hàng'),
            ])),
            const PopupMenuItem(value: 'voucher', child: Row(children: [
              Icon(Icons.local_offer_outlined, size: 18), SizedBox(width: 8), Text('Quản lý Voucher'),
            ])),
          ],
        ),
      ],
      bottom: TabBar(
          controller: _tabController,
          labelColor: TColor.primary,
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: TColor.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Đang bán (${_activeMenu.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pause_circle_outline_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Ngừng bán (${_deletedMenu.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TColor.primary,
        onPressed: () => _showDishEditor(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm món',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 0: Đang bán ──
                _buildMenuList(
                  items: _activeMenu,
                  emptyMessage: 'Chưa có món ăn nào đang bán',
                  emptyIcon: Icons.restaurant_menu_outlined,
                  actionBuilder: (dish) => _buildActiveActions(dish),
                ),

                // ── Tab 1: Ngừng bán ──
                _buildMenuList(
                  items: _deletedMenu,
                  emptyMessage: 'Không có món nào đang ngừng bán',
                  emptyIcon: Icons.pause_circle_outline_rounded,
                  emptyColor: Colors.orange,
                  actionBuilder: (dish) => _buildDeletedActions(dish),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuList({
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
    required IconData emptyIcon,
    Color? emptyColor,
    required Widget Function(Map<String, dynamic>) actionBuilder,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon,
                size: 64, color: (emptyColor ?? Colors.grey).withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(emptyMessage,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllMenus,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 0, endIndent: 0),
        itemBuilder: (_, i) => _buildDishRow(items[i], actionBuilder),
      ),
    );
  }

  Widget _buildDishRow(
    Map<String, dynamic> dish,
    Widget Function(Map<String, dynamic>) actionBuilder,
  ) {
    final name = (dish['tenMonAn'] ?? dish['name'] ?? 'Món ăn').toString();
    final price = _toDouble(dish['giaTien'] ?? dish['price']);
    final imageUrl = (dish['hinhAnh'] ?? dish['imageUrl'] ?? '').toString();
    final isAvail = dish['trangThai'] != 0 && dish['isAvailable'] != false;
    final stock = dish['soLuongTon'] ?? 99;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffItemDetailsView(
              dishObj: dish,
              onEdit: () {
                _showDishEditor(dish: dish);
              },
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
        children: [
          // Dish image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatPrice(price)}đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isAvail ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAvail ? 'Còn hàng' : 'Hết món',
                      style: TextStyle(
                        fontSize: 11,
                        color: isAvail ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.inventory_2_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      'Tồn: $stock',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          actionBuilder(dish),
        ],
      ),
      ),
    );
  }

  // Nút Edit + Ngừng bán (Tab Đang bán)
  Widget _buildActiveActions(Map<String, dynamic> dish) {
    return Column(
      children: [
        _iconBtn(
          icon: Icons.edit_rounded,
          color: TColor.primary,
          onTap: () => _showDishEditor(dish: dish),
        ),
        const SizedBox(height: 8),
        _iconBtn(
          icon: Icons.pause_circle_outline_rounded,
          color: Colors.orange,
          onTap: () => _confirmDelete(dish),
        ),
      ],
    );
  }

  // Nút Khôi phục (Tab Ngừng bán)
  Widget _buildDeletedActions(Map<String, dynamic> dish) {
    return _iconBtn(
      icon: Icons.restore_rounded,
      color: Colors.green,
      onTap: () => _restoreDish(dish),
      tooltip: 'Khôi phục',
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap,
      String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: const Color(0xFFF0F0F0),
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 28),
    );
  }
}
