import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/review.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/review_service.dart';
import '../../widgets/widgets.dart';

/// Nội dung tab "Đánh giá" ở màn chi tiết: tổng hợp sao + danh sách review +
/// form viết/sửa. Tự fetch, tự quản state form. Ai login cũng review được;
/// mỗi user 1 review/SP (sửa & xoá của mình); Admin xoá được review bất kỳ.
class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final _service = ReviewService();
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final list = await _service.fetchReviews(widget.productId);
      if (mounted) setState(() => _reviews = list);
    } catch (_) {
      // im lặng — hiện empty-state, người dùng vẫn viết được.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Review? get _mine {
    for (final r in _reviews) {
      if (r.isMine) return r;
    }
    return null;
  }

  bool get _isLoggedIn => apiClient.userId != null;
  bool get _isAdmin => apiClient.userRole == 'Admin';

  double get _average {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / _reviews.length;
  }

  Future<void> _openForm({Review? existing}) async {
    if (!_isLoggedIn) {
      TvToast.show(context, 'Đăng nhập để viết đánh giá nhé.');
      return;
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReviewFormSheet(productName: widget.productName, initial: existing),
    );
    if (result == null || !mounted) return;
    final rating = result['rating'] as int;
    final comment = result['comment'] as String;
    try {
      if (existing == null) {
        await _service.createReview(widget.productId, rating, comment);
      } else {
        await _service.updateReview(existing.id, rating, comment);
      }
      if (!mounted) return;
      TvToast.show(
        context,
        existing == null ? 'Đã gửi đánh giá!' : 'Đã cập nhật đánh giá.',
      );
      await _load();
    } catch (_) {
      if (mounted) {
        TvToast.show(context, 'Không gửi được đánh giá. Thử lại sau.');
      }
    }
  }

  Future<void> _delete(Review r) async {
    final ok = await showTvConfirm(
      context,
      title: 'Xoá đánh giá',
      message: r.isMine
          ? 'Xoá đánh giá của bạn cho sản phẩm này?'
          : 'Xoá đánh giá của "${r.customerName}"? (quyền quản trị)',
      confirmLabel: 'Xoá',
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteReview(r.id);
      if (!mounted) return;
      TvToast.show(context, 'Đã xoá đánh giá.');
      await _load();
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không xoá được. Thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final mine = _mine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reviews.isEmpty) _empty() else _summary(),
        const SizedBox(height: 16),
        // Nút viết / sửa đánh giá.
        if (mine == null)
          TvButton(
            label: 'Viết đánh giá',
            leadingIcon: const TvIcon('star'),
            fullWidth: true,
            onPressed: () => _openForm(),
          )
        else
          Row(
            children: [
              Expanded(
                child: TvButton(
                  label: 'Sửa đánh giá của bạn',
                  variant: TvButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => _openForm(existing: mine),
                ),
              ),
              const SizedBox(width: 10),
              TvIconButton(
                icon: TvIcon('trash-2', color: AppColors.danger500),
                variant: TvIconButtonVariant.elevated,
                tooltip: 'Xoá đánh giá của bạn',
                onPressed: () => _delete(mine),
              ),
            ],
          ),
        const SizedBox(height: 20),
        for (final r in _reviews) ...[
          _reviewCard(r),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            TvIcon('star', size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Chưa có đánh giá',
              style: AppText.h2().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy là người đầu tiên chia sẻ cảm nhận.',
              textAlign: TextAlign.center,
              style: AppText.sm(AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final total = _reviews.length;
    return TvCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Điểm trung bình lớn.
          Column(
            children: [
              Text(
                _average.toStringAsFixed(1),
                style: AppText.display().copyWith(fontSize: 40),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= _average.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.star500,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$total đánh giá',
                style: AppText.xs(AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Thanh phân bổ 5★ → 1★.
          Expanded(
            child: Column(
              children: [
                for (int star = 5; star >= 1; star--) ...[
                  _distRow(
                    star,
                    _reviews.where((r) => r.rating == star).length,
                    total,
                  ),
                  if (star > 1) const SizedBox(height: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _distRow(int star, int count, int total) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        Text('$star', style: AppText.xs(AppColors.textSecondary)),
        const SizedBox(width: 4),
        Icon(Icons.star_rounded, size: 11, color: AppColors.star500),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.bgOverlay,
              valueColor: AlwaysStoppedAnimation(AppColors.star500),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: AppText.xs(AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(Review r) {
    final time = formatRelativeFromIso(r.createdAt);
    final canDelete = r.isMine || _isAdmin;
    return TvCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.customerName.isEmpty ? 'Khách' : r.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong().copyWith(fontSize: 14),
                      ),
                    ),
                    if (r.isMine) ...[
                      const SizedBox(width: 8),
                      const TvBadge('Của bạn', variant: TvBadgeVariant.accent),
                    ],
                  ],
                ),
              ),
              if (canDelete)
                GestureDetector(
                  onTap: () => _delete(r),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TvIcon(
                      'trash-2',
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  i <= r.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.star500,
                  size: 15,
                ),
              if (time.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(time, style: AppText.xs(AppColors.textTertiary)),
              ],
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: AppText.body(
                AppColors.textSecondary,
              ).copyWith(fontSize: 14, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet form viết/sửa đánh giá — chọn sao + bình luận.
class _ReviewFormSheet extends StatefulWidget {
  const _ReviewFormSheet({required this.productName, this.initial});
  final String productName;
  final Review? initial;

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late int _rating = widget.initial?.rating ?? 5;
  late final TextEditingController _comment = TextEditingController(
    text: widget.initial?.comment ?? '',
  );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppEffects.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Viết đánh giá' : 'Sửa đánh giá',
                style: AppText.h3(),
              ),
              const SizedBox(height: 4),
              Text(
                widget.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sm(AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Chọn sao.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _rating = i),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.star500,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TvInput(
                controller: _comment,
                hintText: 'Chia sẻ cảm nhận của bạn (tuỳ chọn)...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TvButton(
                      label: 'Đóng',
                      variant: TvButtonVariant.ghost,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TvButton(
                      label: 'Gửi',
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop({
                        'rating': _rating,
                        'comment': _comment.text.trim(),
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
