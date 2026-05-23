import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/app_image_view.dart';

/// Màn hình tất cả đánh giá của user hiện tại
class MyReviewsView extends StatefulWidget {
  const MyReviewsView({super.key});
  @override
  State<MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<MyReviewsView> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svMyReviews, isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as List? ?? [];
        setState(() {
          _reviews = data.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Load my reviews error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Đánh giá của tôi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: TColor.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_border_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text('Bạn chưa có đánh giá nào',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Đặt hàng và đánh giá để thấy chúng ở đây',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade400)),
        ]),
      );
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dishName  = review['tenMonAn']?.toString() ?? '';
    final canteen   = review['tenGianHang']?.toString() ?? '';
    final stars     = (review['soSao'] as num?)?.toInt() ?? 0;
    final comment   = review['binhLuan']?.toString() ?? '';
    final dishImg   = review['anhMonAn']?.toString() ?? '';
    final rawDate   = review['thoiGianDanhGia']?.toString();
    final date      = rawDate != null
        ? DateTime.tryParse(rawDate)
        : null;
    final images    = (review['hinhAnhDanhGia'] as List?)
        ?.whereType<String>()
        .toList() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: ảnh + tên món + gian hàng + ngày
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppImageView(
                path: dishImg.isEmpty
                    ? ''
                    : (dishImg.startsWith('http')
                        ? dishImg
                        : '${SVKey.nodeUrl}$dishImg'),
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                placeholderAsset: 'assets/img/app_logo.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dishName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.store_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(canteen,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ]),
            ),
            if (date != null)
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 10),
              ),
          ]),

          const SizedBox(height: 10),

          // Stars
          Row(children: List.generate(5, (i) => Icon(
            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: i < stars ? const Color(0xFFFFC107) : Colors.grey.shade300,
          ))),

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 13,
                    height: 1.4)),
          ],

          // Review images
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImageView(
                    path: images[i].startsWith('http')
                        ? images[i]
                        : '${SVKey.nodeUrl}${images[i]}',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholderAsset: 'assets/img/app_logo.png',
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
