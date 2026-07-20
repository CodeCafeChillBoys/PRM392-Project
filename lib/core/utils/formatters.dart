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
  return '$sign$buffer'
      'đ';
}

/// `mm:ss` countdown formatter — e.g. `120` → `02:00`. Used by the OTP screen.
String formatCountdown(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Khoảng thời gian tương đối tiếng Việt: "Vừa xong", "5 phút trước",
/// "2 giờ trước", "3 ngày trước"; quá 7 ngày trả về "dd/MM/yyyy".
/// [now] cho phép test xác định (mặc định DateTime.now()).
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final d = time;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// Như [formatRelativeTime] nhưng nhận chuỗi ISO (vd `OrderModel.orderDate`).
/// Trả về rỗng nếu chuỗi không parse được — để UI ẩn dòng thời gian.
String formatRelativeFromIso(String iso, {DateTime? now}) {
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  return formatRelativeTime(t, now: now);
}
