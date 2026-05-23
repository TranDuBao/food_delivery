import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/app_image_view.dart';

/// Widget hiển thị một đánh giá — dùng chung cho:
/// - ItemDetailsView (preview 2 đánh giá)
/// - AllReviewsView  (toàn bộ danh sách)
class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;

  /// [compact] = true  → style đơn giản (dùng trong preview)
  /// [compact] = false → style đầy đủ (dùng trong AllReviewsView)
  final bool compact;

  const ReviewCard({super.key, required this.review, this.compact = false});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _helpful = false;
  int _helpfulCount = 0;
  bool _expanded = false;

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int stars =
        (widget.review['soSao'] as num?)?.toInt() ?? 0;
    final String name =
        widget.review['tenNguoiDung']?.toString() ?? 'Khách hàng';
    final String comment =
        widget.review['binhLuan']?.toString() ?? '';
    final String date = _formatDate(widget.review['thoiGianDanhGia']);
    final List images = widget.review['hinhAnhDanhGia'] is List
        ? widget.review['hinhAnhDanhGia']
        : [];

    return Container(
      margin: widget.compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : const EdgeInsets.only(bottom: 14),
      padding: widget.compact
          ? const EdgeInsets.fromLTRB(14, 14, 14, 10)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            widget.compact ? null : BorderRadius.circular(16),
        border: widget.compact
            ? Border(
                bottom:
                    BorderSide(color: Colors.grey.shade100, width: 1))
            : null,
        boxShadow: widget.compact
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Tên + Ngày + (Hữu ích nếu compact) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: widget.compact ? 18 : 20,
                backgroundColor:
                    TColor.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'K',
                  style: TextStyle(
                    color: TColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: widget.compact ? 15 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: widget.compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Stars (full mode: hiển thị bên phải header)
              if (!widget.compact)
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: i < stars
                          ? const Color(0xFFFFC107)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              // Hữu ích (compact mode)
              if (widget.compact)
                GestureDetector(
                  onTap: () => setState(() {
                    _helpful = !_helpful;
                    _helpfulCount += _helpful ? 1 : -1;
                  }),
                  child: Row(
                    children: [
                      Text(
                        'Hữu ích${_helpfulCount > 0 ? ' ($_helpfulCount)' : ''}',
                        style: TextStyle(
                          color: _helpful
                              ? TColor.primary
                              : TColor.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _helpful
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 14,
                        color: _helpful
                            ? TColor.primary
                            : TColor.secondaryText,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Stars (compact mode: hiển thị riêng dòng dưới)
          if (widget.compact)
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 15,
                  color: i < stars
                      ? const Color(0xFFFFC107)
                      : Colors.grey.shade300,
                ),
              ),
            ),

          if (widget.compact) const SizedBox(height: 6),

          // ── Bình luận ──
          if (comment.isNotEmpty) ...[
            if (!widget.compact) const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  setState(() => _expanded = !_expanded),
              child: Text(
                comment,
                style: TextStyle(
                  color:
                      TColor.primaryText.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: _expanded ? 30 : 3,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (comment.length > 120)
              GestureDetector(
                onTap: () =>
                    setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _expanded ? 'Thu gọn' : 'Xem thêm',
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],

          // ── Ảnh đánh giá ──
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length > 4 ? 4 : images.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _showFullImage(
                      context, images[i].toString()),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: AppImageView(
                        path: images[i].toString(),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImageView(path: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
