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

const _readOnes = [
  'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'
];
const _readScales = [
  '', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ', 'triệu tỷ', 'tỷ tỷ'
];

/// Đọc 1 nhóm 3 chữ số (0..999) thành chữ. [full] = đọc cả "không trăm" cho
/// nhóm không đứng đầu (vd 1.005 → "một nghìn không trăm lẻ năm").
String _readTriple(int n, {required bool full}) {
  final tram = n ~/ 100, chuc = (n % 100) ~/ 10, donvi = n % 10;
  final parts = <String>[];
  if (tram > 0) {
    parts..add(_readOnes[tram])..add('trăm');
  } else if (full) {
    parts..add('không')..add('trăm');
  }
  if (chuc > 1) {
    parts..add(_readOnes[chuc])..add('mươi');
    if (donvi == 1) {
      parts.add('mốt');
    } else if (donvi == 5) {
      parts.add('lăm');
    } else if (donvi > 0) {
      parts.add(_readOnes[donvi]);
    }
  } else if (chuc == 1) {
    parts.add('mười');
    if (donvi == 5) {
      parts.add('lăm');
    } else if (donvi > 0) {
      parts.add(_readOnes[donvi]); // "mười một", "mười hai"...
    }
  } else if (donvi > 0) {
    if (tram > 0 || full) parts.add('lẻ'); // "một trăm lẻ năm"
    parts.add(_readOnes[donvi]);
  }
  return parts.join(' ');
}

/// Đọc một số nguyên đồng thành chữ tiếng Việt (không kèm "đồng").
/// Vd: 30000000 → "ba mươi triệu", 1205 → "một nghìn hai trăm lẻ năm".
/// Theo quy tắc hoá đơn: mươi/mười, mốt/một, lăm/năm, lẻ, nghìn/triệu/tỷ.
String readVietnameseNumber(int amount) {
  if (amount == 0) return 'không';
  final negative = amount < 0;
  var n = amount.abs();

  // Tách thành các nhóm 3 chữ số (nhóm thấp nhất trước).
  final groups = <int>[];
  while (n > 0) {
    groups.add(n % 1000);
    n ~/= 1000;
  }

  final segments = <String>[];
  // Đọc từ nhóm cao nhất xuống.
  for (var i = groups.length - 1; i >= 0; i--) {
    final g = groups[i];
    final isLeading = segments.isEmpty;
    if (g == 0) continue; // nhóm toàn 0 → bỏ (vd 1.000.000 → "một triệu")
    final words = _readTriple(g, full: !isLeading);
    final scale = _readScales[i];
    segments.add(scale.isEmpty ? words : '$words $scale');
  }

  final result = segments.join(' ');
  return negative ? 'âm $result' : result;
}

/// Nhãn tiếng Việt cho `PaymentStatus` của đơn (gồm cả trạng thái hoàn tiền).
String paymentStatusLabel(String status) {
  switch (status) {
    case 'Paid':
      return 'Đã thanh toán';
    case 'Refunded':
      return 'Đã hoàn tiền';
    case 'RefundRequested':
      return 'Chờ duyệt hoàn';
    default:
      return 'Chưa TT';
  }
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

/// Ngày giờ đầy đủ từ chuỗi ISO (đã đổi về giờ máy): "14:35 · 06/07/2026".
/// Rỗng nếu không parse được.
String formatDateTimeFromIso(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  final dd = t.day.toString().padLeft(2, '0');
  final mo = t.month.toString().padLeft(2, '0');
  return '$hh:$mm · $dd/$mo/${t.year}';
}

/// Như [formatRelativeTime] nhưng nhận chuỗi ISO (vd `OrderModel.orderDate`).
/// Trả về rỗng nếu chuỗi không parse được — để UI ẩn dòng thời gian.
String formatRelativeFromIso(String iso, {DateTime? now}) {
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  return formatRelativeTime(t, now: now);
}
