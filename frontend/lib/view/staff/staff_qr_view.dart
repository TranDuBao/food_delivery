import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

/// Màn hình Staff — Xem & chia sẻ QR Code của quán.
/// QR chứa deep link: shipfood://canteen/{maGianHang}
/// Khách quét QR → app mở → vào thực đơn quán → đặt món.
class StaffQrView extends StatefulWidget {
  const StaffQrView({super.key});

  @override
  State<StaffQrView> createState() => _StaffQrViewState();
}

class _StaffQrViewState extends State<StaffQrView> {
  final GlobalKey _qrKey = GlobalKey();

  String? _deepLink;
  String? _webLink;
  String? _tenGianHang;
  String? _error;
  bool _isLoading = false;
  int _soBan = 10;
  bool _useWebLink = true; // Mặc định hiển thị link web để dễ quét bằng camera thường/máy tính

  @override
  void initState() {
    super.initState();
    _loadQrInfo();
  }

  Future<void> _loadQrInfo() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ServiceCall.fetchGet(SVKey.svDineInStaffQrInfo, isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map;
        setState(() {
          _deepLink = data['deepLink']?.toString();
          _webLink = data['webLink']?.toString();
          _tenGianHang = data['tenGianHang']?.toString();
          _soBan = int.tryParse(data['soBan']?.toString() ?? '10') ?? 10;
        });
      } else {
        setState(() => _error = 'Không lấy được thông tin QR.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTables(int newCount) async {
    if (newCount <= 0) return;
    Globs.showHUD();
    try {
      final res = await ServiceCall.fetchPut(
        '${SVKey.apiBaseUrl}dine-in/staff/tables',
        isToken: true,
        body: {'soBan': newCount},
      );
      if (res is Map && res['success'] == true) {
        setState(() {
          _soBan = newCount;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật số lượng bàn ăn.')),
          );
        }
        _loadQrInfo();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Lỗi cập nhật số bàn.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      Globs.hideHUD();
    }
  }

  Future<void> _shareQr() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final xFile = XFile.fromData(pngBytes, mimeType: 'image/png', name: 'qr_${_tenGianHang ?? 'canteen'}.png');
      await Share.shareXFiles([xFile], text: 'Quét mã QR để xem thực đơn & đặt món tại ${_tenGianHang ?? 'quán'}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mã QR Quán',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _loadQrInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadQrInfo,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final activeLink = _useWebLink ? (_webLink ?? _deepLink) : _deepLink;
    if (activeLink == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Header banner ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [TColor.primary, TColor.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Mã QR Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _tenGianHang ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Chọn loại Link để quét ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Dùng Web (Chrome/PC)')),
                  selected: _useWebLink,
                  onSelected: (val) {
                    if (val) setState(() => _useWebLink = true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Dùng App (Điện thoại)')),
                  selected: !_useWebLink,
                  onSelected: (val) {
                    if (val) setState(() => _useWebLink = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── QR Code card ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  _useWebLink 
                      ? 'Quét mã này bằng điện thoại/PC để xem menu trên trình duyệt web'
                      : 'Quét mã này bằng điện thoại để mở thẳng ứng dụng đặt món',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // QR với RepaintBoundary để chụp ảnh
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: activeLink,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  _tenGianHang ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: activeLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã copy link vào clipboard')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activeLink,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 12, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Quản lý Số Bàn Ăn ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số lượng bàn ăn',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khách có thể chọn bàn từ 1 đến $_soBan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _soBan > 1 ? () => _updateTables(_soBan - 1) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: TColor.primary,
                      iconSize: 28,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      alignment: Alignment.center,
                      child: Text(
                        '$_soBan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateTables(_soBan + 1),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: TColor.primary,
                      iconSize: 28,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Hướng dẫn ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Hướng dẫn sử dụng',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _step('1', 'Bấm "Chia sẻ QR" để lưu ảnh QR code về máy.'),
                _step('2', 'In ảnh QR ra giấy và dán lên bàn hoặc quầy tính tiền.'),
                _step('3', 'Khách hàng dùng điện thoại quét mã QR.'),
                _step('4', 'App tự động mở thực đơn quán → Chọn món → Thanh toán.'),
                _step('5', 'Đơn của khách sẽ hiển thị trong tab "Đơn tại bàn".'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Nút chia sẻ ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareQr,
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'Chia sẻ QR / Lưu về máy',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
