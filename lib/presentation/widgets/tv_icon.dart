import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';

/// Convenience wrapper mirroring the design system's `Ico(name, size)` helper —
/// resolves a Lucide name to a Material glyph at the given size/color.
class TvIcon extends StatelessWidget {
  const TvIcon(this.name, {super.key, this.size = 20, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(AppIcons.get(name), size: size, color: color);
}
