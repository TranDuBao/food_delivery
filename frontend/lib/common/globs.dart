import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:food_delivery/main.dart';

class Globs {
  static const appName = "Food Delivery";

  static const userPayload = "user_payload";
  static const userLogin = "user_login";

  static void showHUD({String status = "loading ....."}) async {
    await Future.delayed(const Duration(milliseconds: 1));
    EasyLoading.show(status: status);
  }

  static void hideHUD() {
    EasyLoading.dismiss();
  }

  static void udSet(dynamic data, String key) {
    var jsonStr = json.encode(data);
    prefs?.setString(key, jsonStr);
  }

  static void udStringSet(String data, String key) {
    prefs?.setString(key, data);
  }

  static void udBoolSet(bool data, String key) {
    prefs?.setBool(key, data);
  }

  static void udIntSet(int data, String key) {
    prefs?.setInt(key, data);
  }

  static void udDoubleSet(double data, String key) {
    prefs?.setDouble(key, data);
  }

  static dynamic udValue(String key) {
    return json.decode(prefs?.get(key) as String? ?? "{}");
  }

  static String udValueString(String key) {
    return prefs?.get(key) as String? ?? "";
  }

  static bool udValueBool(String key) {
    return prefs?.get(key) as bool? ?? false;
  }

  static bool udValueTrueBool(String key) {
    return prefs?.get(key) as bool? ?? true;
  }

  static int udValueInt(String key) {
    return prefs?.get(key) as int? ?? 0;
  }

  static double udValueDouble(String key) {
    return prefs?.get(key) as double? ?? 0.0;
  }

  static void udRemove(String key) {
    prefs?.remove(key);
  }

  static Future<String> timeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      return timezone.identifier;
    } on PlatformException {
      return "";
    }
  }
}

class SVKey {
  static String get mainUrl =>
      kIsWeb ? "http://127.0.0.1:3001" : "http://10.0.2.2:3001";
  static String get apiBaseUrl => '$mainUrl/api/';
  static String get authBaseUrl => '$apiBaseUrl' 'auth/';
  static String get nodeUrl => mainUrl;

  static String get svLogin => '${authBaseUrl}login';
  static String get svSocialLogin => '${authBaseUrl}social-login';
  static String get svSignUp => '${authBaseUrl}register';
  static String get svForgotPasswordRequest => '${authBaseUrl}forgot-password';
  static String get svForgotPasswordVerify => '${authBaseUrl}reset-password';
  static String get svForgotPasswordSetNew => '${authBaseUrl}reset-password';

  static String get svCanteens => '${apiBaseUrl}canteens';
  static String get svCanteenCategories => '${apiBaseUrl}categories';
  static String get svCanteenDishes => '${apiBaseUrl}mon-an';
  static String get svCustomerSearchCanteens =>
      '${apiBaseUrl}customer/search/canteens';
  static String get svCustomerSearchProducts =>
      '${apiBaseUrl}customer/search/products';
  static String get svCustomerProductDetail => '${apiBaseUrl}customer/products';
  static String get svCustomerProfile => '${apiBaseUrl}customer/me';
  static String get svCustomerChangePassword =>
      '${apiBaseUrl}customer/profile/password';
  static String get svCustomerProfileAvatar =>
      '${apiBaseUrl}customer/profile/avatar';
  /// GET /api/customer/stats — thống kê đơn hàng + chi tiêu
  static String get svCustomerStats    => '${apiBaseUrl}customer/stats';
  /// GET /api/customer/wallet
  static String get svCustomerWallet   => '${apiBaseUrl}customer/wallet';
  /// POST /api/customer/wallet/deposit
  static String get svWalletDeposit    => '${apiBaseUrl}customer/wallet/deposit';
  /// POST /api/customer/wallet/withdraw
  static String get svWalletWithdraw   => '${apiBaseUrl}customer/wallet/withdraw';
  static String get svCustomerCart => '${apiBaseUrl}cart';        // GET  /api/cart
  static String get svCartAdd     => '${apiBaseUrl}cart/add';     // POST /api/cart/add
  static String get svCartUpdate  => '${apiBaseUrl}cart/update';  // PUT  /api/cart/update
  static String get svCartClear   => '${apiBaseUrl}cart/clear';   // DELETE /api/cart/clear
  static String svCartRemove(dynamic dishId) => '${apiBaseUrl}cart/remove/$dishId'; // DELETE
  static String get svCustomerCartItems => '${apiBaseUrl}cart';  // compat alias
  static String get svOrderCheckout   => '${apiBaseUrl}orders/checkout';
  static String get svOrderAreaOrders => '${apiBaseUrl}orders/area-orders';
  static String get svOrderMy         => '${apiBaseUrl}orders/my';
  static String get svOrderStaffPending => '${apiBaseUrl}orders/staff-pending';
  static String get svOrderStaffKDS => '${apiBaseUrl}orders/staff-kds';
  static String svOrderStaffKDSSwipe(dynamic dishId) => '${apiBaseUrl}orders/staff-kds/$dishId/swipe';
  static String svOrderStartPreparing(dynamic id) => '${apiBaseUrl}orders/$id/start';
  static String svOrderMarkReady(dynamic id) => '${apiBaseUrl}orders/$id/ready';
  // kept for compat
  static String get svOrderRequest    => '${apiBaseUrl}orders/checkout';
  static String get svOrderMyActive   => '${apiBaseUrl}orders/my';
  static String get svOrderMyList     => '${apiBaseUrl}orders/my';
  static String svOrderMyDetail(dynamic orderId) => '${apiBaseUrl}orders/my/$orderId';
  static String svOrderMyCancel(dynamic orderId) => '${apiBaseUrl}orders/my/$orderId/cancel';
  static String get svStaffMenuUploadImage => '${apiBaseUrl}staff/menu/upload-image';
  static String svStaffDishImageUpload(dynamic dishId) =>
      '${apiBaseUrl}staff/menu/$dishId/image';
  static String svDishesByCanteen(dynamic canteenId) => '${apiBaseUrl}mon-an/gian-hang/$canteenId';
  static String get svStaffStoreInfo => '${apiBaseUrl}canteens/me/info';
  static String get svStaffStoreMenu => '${apiBaseUrl}mon-an/me/menu';
  static String get svStaffUpdateStoreInfo => '${apiBaseUrl}canteens/me/info';
  static String get svStaffUploadBanner => '${apiBaseUrl}canteens/me/upload-banner'; // Upload banner giĂ n hĂ ng

  static String svStaffDeleteDish(dynamic dishId) => '${apiBaseUrl}mon-an/me/menu/$dishId';
  static String svStaffUpdateDish(dynamic dishId) => '${apiBaseUrl}mon-an/me/menu/$dishId';
  static String get svStaffCreateDish => '${apiBaseUrl}mon-an/me/menu';
  static String get svStaffMenuDeleted => '${apiBaseUrl}mon-an/me/menu/deleted'; // Tab Ngá»«ng bĂ¡n
  static String svStaffRestoreDish(dynamic dishId) => '${apiBaseUrl}mon-an/me/menu/$dishId/restore'; // KhĂ´i phá»¥c
  static String get svStaffUploadDishImage => '${apiBaseUrl}mon-an/me/menu/upload-image'; // Upload áº£nh mĂ³n

  // â”€â”€ Review / Rating â”€â”€
  static String svReviewItems(dynamic orderId) => '${apiBaseUrl}reviews/order/$orderId/items';
  static String svReviewStatus(dynamic orderId) => '${apiBaseUrl}reviews/order/$orderId/status';
  static String svReviewByOrder(dynamic orderId) => '${apiBaseUrl}reviews/order/$orderId';
  static String svReviewSubmit(dynamic orderId) => '${apiBaseUrl}reviews/order/$orderId';
  static String svReviewByDish(dynamic dishId) => '${apiBaseUrl}reviews/dish/$dishId';
  static String get svReviewUploadImage => '${apiBaseUrl}reviews/upload-image';
  /// GET /api/reviews/my — tất cả đánh giá của user hiện tại
  static String get svMyReviews => '${apiBaseUrl}reviews/my';
  static String get svAddress => '${apiBaseUrl}address';

  // ── Payment / SePay ──
  static String get svPaymentCreate     => '${apiBaseUrl}payment/create';
  static String get svPaymentRefund     => '${apiBaseUrl}payment/refund';
  static String svPaymentStatus(dynamic orderId) => '${apiBaseUrl}payment/status/$orderId';
  static String get svSepayWebhook      => '${apiBaseUrl}payment/sepay-webhook';

  // ── Promotions / Vouchers ──────────────────────────────────────────────────
  /// GET /api/promotions  — tất cả voucher đang active
  static String get svPromotions       => '${apiBaseUrl}promotions';
  /// GET /api/promotions/my  — voucher đã lưu của user
  static String get svMyVouchers       => '${apiBaseUrl}promotions/my';
  /// POST /api/promotions/my/:id  — lưu voucher
  static String svSaveVoucher(dynamic id) => '${apiBaseUrl}promotions/my/$id';
  /// DELETE /api/promotions/my/:id  — xoá voucher đã lưu
  static String svRemoveVoucher(dynamic id) => '${apiBaseUrl}promotions/my/$id';
  /// GET  /api/promotions/staff  — staff lấy danh sách của cửa hàng mình
  static String get svStaffPromotions  => '${apiBaseUrl}promotions/staff';
  /// POST /api/promotions/staff  — staff tạo voucher mới
  static String get svStaffCreatePromotion => '${apiBaseUrl}promotions/staff';
  /// PUT  /api/promotions/staff/:id  — staff sửa voucher
  static String svStaffUpdatePromotion(dynamic id) => '${apiBaseUrl}promotions/staff/$id';
  /// DELETE /api/promotions/staff/:id  — staff xoá voucher
  static String svStaffDeletePromotion(dynamic id) => '${apiBaseUrl}promotions/staff/$id';

  // ── Admin APIs (role = 3) ─────────────────────────────────────────────────
  static String get svAdminDashboard     => '${apiBaseUrl}admin/dashboard';
  static String get svAdminMonthlyStats  => '${apiBaseUrl}admin/monthly-stats';
  static String get svAdminOrders        => '${apiBaseUrl}admin/orders';
  static String get svAdminRevenueByStore => '${apiBaseUrl}admin/revenue-by-store';
  static String get svAdminStores        => '${apiBaseUrl}admin/stores';
  static String svAdminUpdateStore(dynamic id) => '${apiBaseUrl}admin/stores/$id';
  static String svAdminDeleteStore(dynamic id) => '${apiBaseUrl}admin/stores/$id';
  static String svAdminStoreBanner(dynamic id) => '${apiBaseUrl}admin/stores/$id/banner';
  static String svAdminStoreStats(dynamic id)  => '${apiBaseUrl}admin/stores/$id/stats';
  static String get svAdminUsers         => '${apiBaseUrl}admin/users';
  static String svAdminUpdateUser(dynamic id) => '${apiBaseUrl}admin/users/$id';
  static String svAdminDeleteUser(dynamic id) => '${apiBaseUrl}admin/users/$id';
  static String get svAdminVouchers      => '${apiBaseUrl}admin/vouchers';
  static String get svAdminStoresList    => '${apiBaseUrl}admin/stores/list';
  static String svAdminUpdateVoucher(dynamic id) => '${apiBaseUrl}admin/vouchers/$id';
  static String svAdminDeleteVoucher(dynamic id) => '${apiBaseUrl}admin/vouchers/$id';

  // ── Delivery Trip APIs (Tab Ship) ─────────────────────────────────────────
  static String get svStaffReadyItems    => '${apiBaseUrl}orders/staff-ready-items';
  static String get svStaffStartTrip     => '${apiBaseUrl}orders/staff-start-trip';
  static String svStaffCompleteTrip(dynamic tripId) => '${apiBaseUrl}orders/staff-complete-trip/$tripId';
  static String svStaffCompleteItem(dynamic itemId) => '${apiBaseUrl}orders/staff-complete-item/$itemId';
  static String get svStaffActiveTrip    => '${apiBaseUrl}orders/staff-active-trip';

  // ── Groups APIs ───────────────────────────────────────────────────────────
  static String get svGroupsCreate       => '${apiBaseUrl}groups/create';
  static String get svMyGroups           => '${apiBaseUrl}groups/my-groups';
  static String get svGroupJoin          => '${apiBaseUrl}groups/join';
  static String get svGroupLeave         => '${apiBaseUrl}groups/leave';
  static String get svGroupRemoveMember  => '${apiBaseUrl}groups/remove-member';
  static String get svGroupDisband       => '${apiBaseUrl}groups/disband';

  static String svDineInMenu(dynamic canteenId) => '${apiBaseUrl}dine-in/menu/$canteenId';
  static String get svDineInCheckout     => '${apiBaseUrl}dine-in/checkout';
  static String get svDineInStaffQrInfo  => '${apiBaseUrl}dine-in/staff/qr-info';
  static String get svDineInTableOrders  => '${apiBaseUrl}dine-in/staff/table-orders';
  static String svDineInTableOrderDetail(dynamic id) => '${apiBaseUrl}dine-in/staff/table-orders/$id';
  static String svDineInStartOrder(dynamic id) => '${apiBaseUrl}dine-in/staff/table-orders/$id/start';
  static String svDineInDoneOrder(dynamic id)  => '${apiBaseUrl}dine-in/staff/table-orders/$id/done';
  static String svDineInAddItem(dynamic id)    => '${apiBaseUrl}dine-in/staff/table-orders/$id/add-item';
  static String svDineInRemoveItem(dynamic orderId, dynamic chiTietId) => '${apiBaseUrl}dine-in/staff/table-orders/$orderId/items/$chiTietId';
  static String get svDineInStaffMenu    => '${apiBaseUrl}dine-in/staff/menu';
  static String get svDineInUpdateTables => '${apiBaseUrl}dine-in/staff/tables';
}

class KKey {
  static const payload = "payload";
  static const status = "status";
  static const message = "message";
  static const authToken = "auth_token";
  static const name = "name";
  static const email = "email";
  static const mobile = "mobile";
  static const address = "address";
  static const userId = "user_id";
  static const resetCode = "reset_code";
  static const resetToken = "resetToken";
}

class MSG {
  static const enterEmail = "Please enter your valid email address.";
  static const enterName = "Please enter your name.";
  static const enterCode = "Please enter valid reset code.";

  static const enterMobile = "Please enter your valid mobile number.";
  static const enterAddress = "Please enter your address.";
  static const enterPassword =
      "Please enter password minimum 8 characters at least.";
  static const enterPasswordNotMatch = "Please enter password not match.";
  static const success = "success";
  static const fail = "fail";
}
  // invite endpoints added below svCustomerCartItems

