import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Renders a product image from either a bundled asset (mock data) or an
/// `http(s)` URL (live backend) — chosen automatically from the path. Shows a
/// branded dark placeholder while loading or on error, so a missing/low-res
/// image never breaks the layout.
///
/// VOID LUXE: ảnh mạng đi qua [CachedNetworkImage] (cache disk+memory,
/// fade-in 300ms) — cuộn list không tải lại, hết spinner generic.
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

  Widget _network(String resolvedUrl) => CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (_, _) => _placeholder(loading: true),
        errorWidget: (_, _, _) => _placeholder(),
      );

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (url.isEmpty) {
      image = _placeholder();
    } else if (_isNetwork) {
      image = _network(url);
    } else if (url.startsWith('/')) {
      // BE trả URL tương đối (vd /uploads/products/x.jpg) → ghép baseUrl.
      image = _network('${ApiConfig.baseUrl}$url');
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

  /// Placeholder tối giản — khối lặng ink900, không spinner (skeleton/fade-in
  /// lo phần chuyển cảnh; spinner xoay là "AI slop" đã nghỉ hưu).
  Widget _placeholder({bool loading = false}) => ColoredBox(
        color: loading ? AppColors.ink900 : AppColors.bgElevated,
        child: loading
            ? const SizedBox.shrink()
            : Center(
                child: Icon(AppIcons.get('shopping-bag'),
                    color: AppColors.textTertiary, size: 30),
              ),
      );
}
