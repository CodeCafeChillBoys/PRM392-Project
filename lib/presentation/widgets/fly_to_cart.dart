import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import 'product_image.dart';

/// Hiệu ứng "bay vào giỏ" — ảnh sản phẩm rời khỏi card, bay theo đường cong
/// tới icon giỏ hàng rồi thu nhỏ dần và tan.
///
/// Cách dùng: đánh dấu icon giỏ bằng [cartIconKey] (GlobalKey), rồi gọi
/// [FlyToCart.launch] với key của widget nguồn (ảnh sản phẩm).
///
/// Kỹ thuật: chèn một [OverlayEntry] vào Overlay gốc nên "vật bay" nổi trên
/// mọi thứ (kể cả sticky bar) và không bị cây widget nguồn rebuild làm gián
/// đoạn. Toạ độ lấy bằng RenderBox.localToGlobal của nguồn & đích.
class FlyToCart {
  FlyToCart._();

  /// Key gắn vào icon giỏ hàng (app bar hoặc bottom nav) — đích đến của bay.
  static final GlobalKey cartIconKey = GlobalKey();

  /// Bắn 1 "vật bay" từ [sourceKey] tới icon giỏ. Không làm gì nếu thiếu toạ độ
  /// (vd icon giỏ không hiển thị trên màn hiện tại) — hiệu ứng chỉ là trang trí,
  /// không được phép làm hỏng luồng thêm giỏ.
  static void launch({
    required BuildContext context,
    required GlobalKey sourceKey,
    required String imageUrl,
  }) {
    if (AppEffects.motionScale(context) == 0) return; // tôn trọng reduce-motion

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final srcBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final dstBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || srcBox == null || dstBox == null) return;
    if (!srcBox.hasSize || !dstBox.hasSize) return;

    final start = srcBox.localToGlobal(Offset.zero);
    final startSize = srcBox.size;
    final end = dstBox.localToGlobal(
      dstBox.size.center(Offset.zero),
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flyer(
        start: start,
        startSize: startSize,
        end: end,
        imageUrl: imageUrl,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Flyer extends StatefulWidget {
  const _Flyer({
    required this.start,
    required this.startSize,
    required this.end,
    required this.imageUrl,
    required this.onDone,
  });

  final Offset start;
  final Size startSize;
  final Offset end;
  final String imageUrl;
  final VoidCallback onDone;

  @override
  State<_Flyer> createState() => _FlyerState();
}

class _FlyerState extends State<_Flyer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Đường bay cong: đi lên trước rồi rơi vào giỏ (parabol nhẹ) — tự nhiên hơn
  /// đường thẳng, giống vật được "hất" vào giỏ.
  Offset _positionAt(double t) {
    final x = widget.start.dx + (widget.end.dx - widget.start.dx) * t;
    final linearY = widget.start.dy + (widget.end.dy - widget.start.dy) * t;
    // Bướu parabol: cao nhất ở giữa quãng, biên độ theo khoảng cách dọc.
    final arc = -70.0 * (4 * t * (1 - t));
    return Offset(x, linearY + arc);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = AppEffects.easeStandard.transform(_c.value);
        final pos = _positionAt(t);
        // Thu nhỏ dần về cỡ icon; mờ đi ở đoạn cuối.
        final scale = 1.0 - 0.72 * t;
        final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
        final w = widget.startSize.width * scale;
        final h = widget.startSize.height * scale;
        return Positioned(
          left: pos.dx + (widget.startSize.width - w) / 2,
          top: pos.dy + (widget.startSize.height - h) / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0, 1),
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.borderAccent, width: 1.5),
                  boxShadow: AppEffects.shadowMd,
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductImage(url: widget.imageUrl),
              ),
            ),
          ),
        );
      },
    );
  }
}
