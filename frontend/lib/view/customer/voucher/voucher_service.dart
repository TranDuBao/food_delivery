// lib/view/customer/voucher/voucher_service.dart
// Quản lý voucher: gọi API backend thay vì mock data.

import 'package:flutter/foundation.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'voucher_model.dart';

class VoucherService extends ChangeNotifier {
  VoucherService._();
  static final VoucherService instance = VoucherService._();

  // ── State ──────────────────────────────────────────────────────────────────
  List<Voucher> _available = [];
  List<Voucher> _myVouchers = [];
  bool _loading = false;
  String? _error;

  List<Voucher> get availableVouchers => _available;
  List<Voucher> get myVouchers => _myVouchers;
  bool get isLoading => _loading;
  String? get error => _error;

  // ── Check đã thu thập chưa ─────────────────────────────────────────────────
  bool hasCollected(String voucherId) =>
      _myVouchers.any((v) => v.id == voucherId);

  // ── Load danh sách voucher đang active từ backend ─────────────────────────
  Future<void> loadAvailable({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ServiceCall.fetchGet(
        SVKey.svPromotions,
        // Public endpoint - không cần token
      );
      if (kDebugMode) print('[VoucherService] loadAvailable response: $data');
      if (data is List) {
        // Backend đã filter is_active=TRUE AND ends_at>=NOW() → không cần filter thêm
        _available = data
            .map((e) => Voucher.fromBackend(e as Map<String, dynamic>))
            .toList();
        if (kDebugMode) print('[VoucherService] loaded ${_available.length} vouchers');
      } else {
        if (kDebugMode) print('[VoucherService] unexpected response type: ${data.runtimeType}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('[VoucherService] loadAvailable ERROR: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Load voucher đã lưu của user ──────────────────────────────────────────
  Future<void> loadMyVouchers() async {
    try {
      final data = await ServiceCall.fetchGet(
        SVKey.svMyVouchers,
        isToken: true,
      );
      if (data is List) {
        _myVouchers = data
            .map((e) => Voucher.fromBackend(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('VoucherService.loadMyVouchers error: $e');
    }
  }

  // ── Thu thập voucher (lưu vào server + cập nhật local) ───────────────────
  Future<bool> collectVoucher(Voucher v) async {
    try {
      await ServiceCall.fetchPost(
        SVKey.svSaveVoucher(v.id),
        isToken: true,
      );
      if (!hasCollected(v.id)) {
        _myVouchers.insert(0, v);
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('VoucherService.collectVoucher error: $e');
      return false;
    }
  }

  // ── Xoá voucher khỏi túi ─────────────────────────────────────────────────
  Future<void> removeVoucher(String id) async {
    try {
      await ServiceCall.fetchDelete(
        SVKey.svRemoveVoucher(id),
        isToken: true,
      );
      _myVouchers.removeWhere((v) => v.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('VoucherService.removeVoucher error: $e');
    }
  }

  // ── Xoá session khi logout ────────────────────────────────────────────────
  void clearSession() {
    _available = [];
    _myVouchers = [];
    _error = null;
    notifyListeners();
  }
}
