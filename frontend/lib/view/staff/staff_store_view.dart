import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/app_alert.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class StaffStoreView extends StatefulWidget {
  const StaffStoreView({super.key});

  @override
  State<StaffStoreView> createState() => _StaffStoreViewState();
}

class _StaffStoreViewState extends State<StaffStoreView> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isViewMode = false;

  Map<String, dynamic> _info = {};

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _openHoursCtrl = TextEditingController();

  /// Ảnh banner hiện tại (URL từ server)
  String _currentBannerUrl = '';

  /// File ảnh mới đã chọn nhưng chưa upload
  File? _localBannerFile;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _openHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() => _isLoading = true);
    try {
      final res = await ServiceCall.fetchGet(
        SVKey.svStaffStoreInfo,
        isToken: true,
      );
      if (res is Map && res['data'] != null) {
        final d = Map<String, dynamic>.from(res['data'] as Map);
        setState(() {
          _info = d;
          _nameCtrl.text = d['tenGianHang']?.toString() ?? '';
          _descCtrl.text = d['moTa']?.toString() ?? '';
          _phoneCtrl.text = d['soDienThoai']?.toString() ?? '';
          final open = d['gioMoCua']?.toString() ?? '';
          final close = d['gioDongCua']?.toString() ?? '';
          _openHoursCtrl.text = (open.isNotEmpty && close.isNotEmpty)
              ? '$open - $close'
              : open.isNotEmpty
                  ? open
                  : '';
          _currentBannerUrl =
              (d['banner'] ?? d['hinhAnh'] ?? '').toString();
          _isViewMode = _nameCtrl.text.trim().isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('[StaffStore] load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Chọn ảnh từ gallery ──
  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() {
        _localBannerFile = File(picked.path);
      });
    }
  }

  // ── Upload banner + save store info ──
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên canteen không được để trống')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String finalBannerUrl = _currentBannerUrl;

      // Upload ảnh mới nếu người dùng đã chọn
      if (_localBannerFile != null) {
        Globs.showHUD(status: 'Đang tải ảnh...');
        final uploaded = await ServiceCall.uploadImageFile(
          SVKey.svStaffUploadBanner,
          XFile(_localBannerFile!.path),
          fieldName: 'image',
        );
        Globs.hideHUD();
        if (uploaded != null) {
          finalBannerUrl = uploaded;
        }
      }

      final payload = {
        'tenGianHang': _nameCtrl.text.trim(),
        'moTa': _descCtrl.text.trim(),
        'soDienThoai': _phoneCtrl.text.trim(),
        'gioMoCua': _openHoursCtrl.text.trim(),
        if (finalBannerUrl.isNotEmpty) 'banner': finalBannerUrl,
      };

      await ServiceCall.fetchPut(
        SVKey.svStaffUpdateStoreInfo,
        body: payload,
        isToken: true,
      );

      setState(() {
        _info['tenGianHang'] = _nameCtrl.text.trim();
        _info['moTa'] = _descCtrl.text.trim();
        _info['soDienThoai'] = _phoneCtrl.text.trim();
        _currentBannerUrl = finalBannerUrl;
        _localBannerFile = null; // clear local file
        _isViewMode = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Globs.hideHUD();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isViewMode ? 'Thông tin gian hàng' : 'Chỉnh sửa gian hàng',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isViewMode)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: TColor.primary),
              onPressed: () => setState(() => _isViewMode = false),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isViewMode
              ? _buildViewMode()
              : _buildEditForm(),
    );
  }

  // ─── VIEW MODE ────────────────────────────────────────────────────────────────
  Widget _buildViewMode() {
    final bannerUrl = _currentBannerUrl;
    final name = (_info['tenGianHang'] ?? '').toString();
    final desc = (_info['moTa'] ?? '').toString();
    final phone = (_info['soDienThoai'] ?? '').toString();
    final hours = _openHoursCtrl.text;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          Stack(
            children: [
              bannerUrl.isNotEmpty && bannerUrl.startsWith('http')
                  ? Image.network(
                      bannerUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerPlaceholder(),
                    )
                  : _bannerPlaceholder(),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => setState(() => _isViewMode = false),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoField('Tên gian hàng', name),
                const SizedBox(height: 16),
                _infoField('Mô tả', desc),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _infoField('Số điện thoại',
                            phone.isNotEmpty ? phone : '---')),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _infoField('Giờ mở cửa',
                            hours.isNotEmpty ? hours : '---')),
                  ],
                ),
                const SizedBox(height: 32),
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
                    onPressed: () => setState(() => _isViewMode = false),
                    child: const Text(
                      'Cập nhật thông tin',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '---',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── EDIT FORM ────────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner picker ──
          const Text(
            'Ảnh banner gian hàng',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickBanner,
            child: Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: TColor.primary.withOpacity(0.35), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildBannerPreview(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickBanner,
              icon: Icon(Icons.photo_library_rounded,
                  color: TColor.primary, size: 18),
              label: Text(
                _localBannerFile != null
                    ? 'Đổi ảnh khác'
                    : 'Chọn ảnh từ thư viện',
                style: TextStyle(
                    color: TColor.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Canteen Name
          _buildLabel('Tên gian hàng'),
          const SizedBox(height: 6),
          _buildInput(_nameCtrl, hint: 'VD: Quán Cơm Bà Bảy'),

          const SizedBox(height: 16),

          // Description
          _buildLabel('Mô tả'),
          const SizedBox(height: 6),
          _buildInput(
            _descCtrl,
            hint: 'Mô tả về gian hàng của bạn...',
            maxLines: 4,
          ),

          const SizedBox(height: 16),

          // Phone + Hours
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Số điện thoại'),
                    const SizedBox(height: 6),
                    _buildInput(_phoneCtrl,
                        hint: '0911111111',
                        keyboard: TextInputType.phone),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Giờ mở cửa'),
                    const SizedBox(height: 6),
                    _buildInput(_openHoursCtrl, hint: '07:00 - 15:30'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Save button
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
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBannerPreview() {
    if (_localBannerFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_localBannerFile!, fit: BoxFit.cover),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      );
    }

    if (_currentBannerUrl.isNotEmpty &&
        _currentBannerUrl.startsWith('http')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _currentBannerUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _uploadPlaceholderContent(),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      );
    }

    return _uploadPlaceholderContent();
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555)),
    );
  }

  Widget _buildInput(TextEditingController ctrl,
      {String hint = '',
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFFE8E8E8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Chưa có ảnh banner',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _uploadPlaceholderContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: TColor.primary.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text(
          'Nhấn để chọn ảnh banner',
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Tỉ lệ khuyến nghị 16:9',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      ],
    );
  }
}
