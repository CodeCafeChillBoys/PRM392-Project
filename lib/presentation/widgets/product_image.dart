import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Renders a product image from either a bundled asset (mock data) or an
/// `http(s)` URL (live backend) — chosen automatically from the path. Shows a
/// branded dark placeholder while loading or on error, so a missing/low-res
/// image never breaks the layout.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.dimmed = false,
  });

  final String url;
  final BoxFit fit;

  /// Dim to 40% — used for sold-out products (matches the source).
  final bool dimmed;

  bool get _isNetwork => url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (url.isEmpty) {
      image = _placeholder();
    } else if (_isNetwork) {
      image = Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(loading: true),
      );
    } else {
      image = Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    image = SizedBox.expand(child: image);
    return dimmed ? Opacity(opacity: 0.4, child: image) : image;
  }

  Widget _placeholder({bool loading = false}) => ColoredBox(
        color: AppColors.bgElevated,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(AppIcons.get('shopping-bag'),
                  color: AppColors.textTertiary, size: 30),
        ),
      );
}
