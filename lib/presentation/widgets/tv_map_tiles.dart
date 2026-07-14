import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/config/goong_config.dart';
import '../../core/theme/app_colors.dart';

/// Lớp nền bản đồ dùng chung (OSM raster) — tự hoà tông theo theme.
///
/// OSM chỉ có tile SÁNG. Ở dark mode nền trắng chói đập vào giữa canvas đen
/// nhìn rất lệch, nên ta phủ một ma trận màu: đảo sáng (invert) + xoay nhẹ hue
/// để đường/nước không bị đảo thành màu "âm bản" kỳ dị — kết quả là bản đồ tối
/// vẫn đọc được nhãn, hợp tông VOID LUXE. Light mode dùng tile gốc (đẹp sẵn).
///
/// Dùng thay cho `TileLayer(urlTemplate: GoongConfig.osmTileUrl, ...)` ở mọi
/// [FlutterMap] để 3 màn bản đồ (tracking, checkout, staff) đồng nhất.
class TvMapTiles extends StatelessWidget {
  const TvMapTiles({super.key});

  /// Ma trận 5x4: invert kênh RGB rồi hạ tương phản nhẹ + ám xanh lạnh.
  /// (nghịch đảo: out = 255 - in, sau đó nén dải về [26..229] cho đỡ gắt)
  static const List<double> _darkMatrix = <double>[
    -0.79, 0.12, 0.12, 0, 222, //
    0.12, -0.79, 0.12, 0, 222, //
    0.12, 0.12, -0.79, 0, 232, // hơi ám xanh (kênh B sáng hơn chút)
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: GoongConfig.osmTileUrl,
      userAgentPackageName: 'com.techstore.tech_void',
    );
    if (AppColors.isLight) return tiles;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_darkMatrix),
      child: tiles,
    );
  }
}
