import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';

// ═══════════════════════════════════════════════════════
// MÀN HÌNH ĐÁNH GIÁ SẢN PHẨM (phong cách Shopee)
// ═══════════════════════════════════════════════════════
class ReviewOrderView extends StatefulWidget {
  final dynamic maDonHang;
  final String? danhSachMon; // tên các món (hiển thị phụ)

  const ReviewOrderView({
    super.key,
    required this.maDonHang,
    this.danhSachMon,
  });

  @override
  State<ReviewOrderView> createState() => _ReviewOrderViewState();
}

class _ReviewOrderViewState extends State<ReviewOrderView>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _alreadyReviewed = false;
  List<Map<String, dynamic>> _items = [];

  // { maMonAn: { soSao: int, binhLuan: String } }
  final Map<int, _ReviewEntry> _entries = {};

  // Animation controller cho các ngôi sao
  late AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadItems();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      // Kiểm tra trạng thái đánh giá
      final statusRes = await ServiceCall.fetchGet(
        SVKey.svReviewStatus(widget.maDonHang),
        isToken: true,
      );
      if (statusRes is Map && statusRes['success'] == true) {
        final data = statusRes['data'] as Map?;
        final tongMon = (data?['tongMon'] as num?)?.toInt() ?? 0;
        final daGui = (data?['daGuiDanhGia'] as num?)?.toInt() ?? 0;
        if (tongMon > 0 && daGui >= tongMon) {
          // Đã đánh giá hết, load lại để xem
          await _loadExistingReviews();
          setState(() {
            _alreadyReviewed = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Chưa đánh giá → lấy danh sách món
      final res = await ServiceCall.fetchGet(
        SVKey.svReviewItems(widget.maDonHang),
        isToken: true,
      );
      if (res is Map && res['success'] == true) {
        final data = res['data'] as List? ?? [];
        final items = data.whereType<Map>().map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        // Khởi tạo entries mặc định cho từng món
        for (final item in items) {
          final id = (item['maMonAn'] as num?)?.toInt() ?? 0;
          final existingStars = (item['daDanhGia'] as num?)?.toInt();
          _entries[id] = _ReviewEntry(soSao: existingStars ?? 0);
        }

        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load review items error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingReviews() async {
    try {
      final res = await ServiceCall.fetchGet(
        SVKey.svReviewByOrder(widget.maDonHang),
        isToken: true,
      );
      if (res is Map && res['success'] == true) {
        final data = res['data'] as List? ?? [];
        final items = data.whereType<Map>().map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();
        setState(() => _items = items);
      }
    } catch (e) {
      debugPrint('Load existing reviews error: $e');
    }
  }

  Future<void> _submitReview() async {
    // Kiểm tra tất cả món đã được chọn sao
    final unrated = _items.where((item) {
      final id = (item['maMonAn'] as num?)?.toInt() ?? 0;
      return (_entries[id]?.soSao ?? 0) == 0;
    }).toList();

    if (unrated.isNotEmpty) {
      final tenMon = unrated.first['tenMonAn']?.toString() ?? 'món ăn';
      _showSnack('Vui lòng chọn số sao cho "$tenMon"', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reviews = await Future.wait(_items.map((item) async {
        final id = (item['maMonAn'] as num?)?.toInt() ?? 0;
        final entry = _entries[id]!;

        // Upload ảnh trước (nếu có)
        List<String> uploadedUrls = [];
        for (final file in entry.hinhAnhFiles) {
          try {
            final url = await ServiceCall.uploadImageFile(
              SVKey.svReviewUploadImage,
              file,
              fieldName: 'image',
            );
            if (url != null) uploadedUrls.add(url);
          } catch (e) {
            debugPrint('Upload ảnh lỗi: $e');
          }
        }

        return {
          'maMonAn': id,
          'soSao': entry.soSao,
          'binhLuan': entry.binhLuan.isNotEmpty ? entry.binhLuan : null,
          if (uploadedUrls.isNotEmpty) 'hinhAnhDanhGia': uploadedUrls,
        };
      }));

      final res = await ServiceCall.fetchPost(
        SVKey.svReviewSubmit(widget.maDonHang),
        isToken: true,
        body: {'reviews': reviews},
      );

      if (res is Map && res['success'] == true) {
        HapticFeedback.mediumImpact();
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        _showSnack(
          (res is Map ? res['message'] : null) ?? 'Không thể gửi đánh giá.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, val, child) =>
                    Transform.scale(scale: val, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFEE4D2D), const Color(0xFFFF7043)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEE4D2D).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cảm ơn bạn!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Đánh giá của bạn giúp cải thiện\nchất lượng phục vụ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // đóng dialog
                    Navigator.pop(context); // quay lại lịch sử đơn
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE4D2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Xong',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEE4D2D)))
                : _alreadyReviewed
                    ? _buildAlreadyReviewedView()
                    : _buildReviewForm(),
          ),
          if (!_alreadyReviewed && !_isLoading) _buildSubmitBar(),
        ],
      ),
    );
  }

  // ─── Header kiểu Shopee ───
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEE4D2D), Color(0xFFFF6B4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Text(
                  _alreadyReviewed ? 'Đánh giá của bạn' : 'Đánh giá sản phẩm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Form đánh giá ───
  Widget _buildReviewForm() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Hướng dẫn
        _buildGuideBox(),
        const SizedBox(height: 12),
        // Các card món
        ..._items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final id = (item['maMonAn'] as num?)?.toInt() ?? 0;
          final reviewEntry = _entries[id] ??= _ReviewEntry();

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + idx * 80),
            curve: Curves.easeOut,
            builder: (_, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, (1 - val) * 20),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemReviewCard(
                item: item,
                entry: reviewEntry,
                onChanged: () => setState(() {}),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Hướng dẫn box ─
  Widget _buildGuideBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEE4D2D).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEE4D2D).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFFEE4D2D), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Xem hướng dẫn đánh giá chuẩn để nhận đến\n200 xu thưởng!',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF666666)),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFEE4D2D), size: 20),
        ],
      ),
    );
  }

  // ─── View khi đã review rồi ─
  Widget _buildAlreadyReviewedView() {
    if (_items.isEmpty) {
      return const Center(child: Text('Không có dữ liệu đánh giá.'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 22),
              const SizedBox(width: 10),
              Text(
                'Bạn đã đánh giá đơn hàng này.',
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ..._items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewedItemCard(item: item),
            )),
      ],
    );
  }

  // ─── Bottom submit bar ─
  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEE4D2D),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Hoàn thành',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// MODEL: Entry cho từng món
// ═══════════════════════════════════════════════════════
class _ReviewEntry {
  int soSao;
  String binhLuan;
  List<File> hinhAnhFiles;
  _ReviewEntry({this.soSao = 0, this.binhLuan = '', List<File>? hinhAnhFiles})
      : hinhAnhFiles = hinhAnhFiles ?? [];
}

// ═══════════════════════════════════════════════════════
// WIDGET: Card đánh giá từng món (chưa đánh giá)
// ═══════════════════════════════════════════════════════
class _ItemReviewCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final _ReviewEntry entry;
  final VoidCallback onChanged;

  const _ItemReviewCard({
    required this.item,
    required this.entry,
    required this.onChanged,
  });

  @override
  State<_ItemReviewCard> createState() => _ItemReviewCardState();
}

class _ItemReviewCardState extends State<_ItemReviewCard> {
  late TextEditingController _textCtrl;
  final _starLabels = ['', 'Rất tệ', 'Tệ', 'Bình thường', 'Tốt', 'Tuyệt vời'];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.entry.binhLuan);
    _textCtrl.addListener(() {
      widget.entry.binhLuan = _textCtrl.text;
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _setStar(int star) {
    HapticFeedback.selectionClick();
    setState(() => widget.entry.soSao = star);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isRated = widget.entry.soSao > 0;
    final starLabel = isRated ? _starLabels[widget.entry.soSao] : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thông tin món ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ảnh món
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _ItemImage(url: item['hinhAnh']?.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên gian hàng
                      Text(
                        item['tenGianHang']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFEE4D2D),
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      // Tên món
                      Text(
                        item['tenMonAn']?.toString() ?? 'Món ăn',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Phân loại
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Phân loại: ${item['tenGianHang'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888888)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Chất lượng sản phẩm + Sao ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chất lượng sản phẩm',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final starNum = i + 1;
                      return GestureDetector(
                        onTap: () => _setStar(starNum),
                        child: AnimatedScale(
                          scale: widget.entry.soSao >= starNum ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              widget.entry.soSao >= starNum
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: widget.entry.soSao >= starNum
                                  ? const Color(0xFFFFBB00)
                                  : const Color(0xFFCCCCCC),
                              size: 38,
                            ),
                          ),
                        ),
                      );
                    }),
                    if (isRated) ...[
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          starLabel,
                          key: ValueKey(starLabel),
                          style: const TextStyle(
                              color: Color(0xFFEE4D2D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Bình luận ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bình luận của bạn',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444)),
                    ),
                    Text(
                      'Để lại đánh giá để nhận\nvới xu',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText:
                          'Hãy chia sẻ nhận xét cho sản phẩm này bạn nhé!',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      counterStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          // ── Chọn ảnh đánh giá ──
          _ImagePickerSection(entry: widget.entry),

        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGET: Chọn ảnh đánh giá
// ═══════════════════════════════════════════════════════
class _ImagePickerSection extends StatefulWidget {
  final _ReviewEntry entry;
  const _ImagePickerSection({required this.entry});

  @override
  State<_ImagePickerSection> createState() => _ImagePickerSectionState();
}

class _ImagePickerSectionState extends State<_ImagePickerSection> {
  final _picker = ImagePicker();
  static const _maxImages = 5;

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 70);
      if (picked.isEmpty) return;
      final remaining = _maxImages - widget.entry.hinhAnhFiles.length;
      final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
      if (toAdd.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tối đa 5 ảnh mỗi đánh giá')),
          );
        }
        return;
      }
      setState(() => widget.entry.hinhAnhFiles.addAll(toAdd));
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => widget.entry.hinhAnhFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.entry.hinhAnhFiles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20, color: Color(0xFFF0F0F0)),
          const Text(
            'Thêm hình ảnh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Nút thêm ảnh
                if (files.length < _maxImages)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 78,
                      height: 78,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEE4D2D),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined,
                              color: Color(0xFFEE4D2D), size: 28),
                          SizedBox(height: 4),
                          Text('Thêm ảnh',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFEE4D2D),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                // Hiển thị ảnh đã chọn
                ...files.asMap().entries.map((e) {
                  return Stack(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(
                            e.value,
                            width: 78,
                            height: 78,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => _removeImage(e.key),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGET: Card xem lại đánh giá đã gửi
// ═══════════════════════════════════════════════════════
class _ReviewedItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ReviewedItemCard({required this.item});

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '${SVKey.mainUrl}$path';
    return path;
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _resolveImageUrl(url),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soSao = (item['soSao'] as num?)?.toInt() ?? 0;
    final binhLuan = item['binhLuan']?.toString() ?? '';
    final List<String> images = (() {
      final raw = item['hinhAnhDanhGia'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return <String>[];
    })();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ItemImage(url: item['hinhAnh']?.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['tenMonAn']?.toString() ?? 'Món ăn',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < soSao ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i < soSao
                            ? const Color(0xFFFFBB00)
                            : const Color(0xFFCCCCCC),
                        size: 20,
                      ),
                    ),
                  ),
                  if (binhLuan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        binhLuan,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF555555)),
                      ),
                    ),
                  ],
                  // ── Ảnh đánh giá ──
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 76,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (ctx, i) {
                          final imgUrl = _resolveImageUrl(images[i]);
                          return GestureDetector(
                            onTap: () => _showFullImage(ctx, images[i]),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.network(
                                  imgUrl,
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF0F0F0),
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Color(0xFFCCCCCC),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════
// WIDGET: Hiển thị ảnh món ăn với fallback
// ═══════════════════════════════════════════════════════
class _ItemImage extends StatelessWidget {
  final String? url;
  const _ItemImage({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: (url != null && url!.startsWith('http'))
          ? Image.network(
              url!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _ItemImagePlaceholder(),
            )
          : const _ItemImagePlaceholder(),
    );
  }
}

class _ItemImagePlaceholder extends StatelessWidget {
  const _ItemImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFE0D4), const Color(0xFFFFCCBB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood_rounded,
          color: Color(0xFFEE4D2D), size: 32),
    );
  }
}
