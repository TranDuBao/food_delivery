// lib/view/customer/voucher/voucher_model.dart

class Voucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final String restaurantName; // canteenName từ backend
  final String restaurantId;   // canteenId từ backend
  final String? categoryName;  // dishName hoặc categoryName — null = tất cả món
  final double discountPercent;
  final double? maxDiscount;
  final int totalQuantity;     // không có trong backend → default 999
  final int usedQuantity;      // không có trong backend → default 0
  final DateTime expiredAt;    // endsAt từ backend
  final String? imageUrl;      // bannerImageUrl từ backend

  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.restaurantName,
    required this.restaurantId,
    this.categoryName,
    required this.discountPercent,
    this.maxDiscount,
    required this.totalQuantity,
    required this.usedQuantity,
    required this.expiredAt,
    this.imageUrl,
  });

  // Còn lại bao nhiêu lượt (-1 = không giới hạn)
  int get remainingQuantity =>
      totalQuantity < 0 ? 999999 : totalQuantity - usedQuantity;

  // Không giới hạn khi totalQuantity == -1
  bool get isUnlimited => totalQuantity < 0;

  // Còn hiệu lực không
  bool get isValid =>
      remainingQuantity > 0 && expiredAt.isAfter(DateTime.now());

  // Số ngày còn lại
  int get daysLeft => expiredAt.difference(DateTime.now()).inDays;

  /// Parse từ response backend (promotions table)
  factory Voucher.fromBackend(Map<String, dynamic> json) {
    // endsAt có thể là ISO string hoặc Date object từ MySQL
    DateTime parsedExpiry = DateTime.now().add(const Duration(days: 30));
    final rawEnd = json['endsAt'] ?? json['ends_at'];
    if (rawEnd != null) {
      parsedExpiry = DateTime.tryParse(rawEnd.toString()) ?? parsedExpiry;
    }

    // MySQL DECIMAL trả về String "20.00" → cần parse an toàn
    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    // Tên danh mục: ưu tiên dishName, fallback categoryName
    final catName = (json['dishName'] ?? json['categoryName'])?.toString();

    return Voucher(
      id: (json['promotionId'] ?? json['id'] ?? '').toString(),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      restaurantName: json['canteenName']?.toString() ?? '',
      restaurantId: (json['canteenId'] ?? '').toString(),
      categoryName: (catName?.isNotEmpty == true) ? catName : null,
      discountPercent: parseDouble(json['discountPercent']),
      maxDiscount: null,
      // max_uses == null → không giới hạn → dùng -1
      totalQuantity: json['maxUses'] != null
          ? (json['maxUses'] as num).toInt()
          : -1,
      usedQuantity: 0,
      expiredAt: parsedExpiry,
      imageUrl: json['bannerImageUrl']?.toString(),
    );
  }

  /// Giữ lại fromJson cũ để tương thích nếu cần
  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        restaurantName: json['restaurantName']?.toString() ?? '',
        restaurantId: json['restaurantId']?.toString() ?? '',
        categoryName: json['categoryName']?.toString(),
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
        totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 999,
        usedQuantity: (json['usedQuantity'] as num?)?.toInt() ?? 0,
        expiredAt: DateTime.tryParse(json['expiredAt']?.toString() ?? '') ??
            DateTime.now(),
        imageUrl: json['imageUrl']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'categoryName': categoryName,
        'discountPercent': discountPercent,
        'maxDiscount': maxDiscount,
        'totalQuantity': totalQuantity,
        'usedQuantity': usedQuantity,
        'expiredAt': expiredAt.toIso8601String(),
        'imageUrl': imageUrl,
      };
}
