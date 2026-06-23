// Formatting helpers shared across the UI.

/// Format a number as Vietnamese đồng with dot thousands separators and a `đ`
/// suffix — e.g. `34990000` → `34.990.000đ`. Mirrors `data.js`'s `fmt()`.
String formatVnd(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final sign = rounded < 0 ? '-' : '';
  return '$sign$buffer' 'đ';
}

/// `mm:ss` countdown formatter — e.g. `120` → `02:00`. Used by the OTP screen.
String formatCountdown(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
