import 'package:latlong2/latlong.dart';

/// Kết quả tính phí ship từ BE `POST /api/shipping/calculate` (BE dùng Goong
/// tính theo khoảng cách thực tế kho → nhà khách).
class ShippingQuote {
  const ShippingQuote({
    required this.distanceKm,
    required this.durationMinutes,
    required this.shippingFee,
    required this.routePolyline,
  });

  final double distanceKm;
  final double durationMinutes;
  final double shippingFee;
  final String routePolyline; // encoded polyline (Google format) để vẽ tuyến

  factory ShippingQuote.fromJson(Map<String, dynamic> json) => ShippingQuote(
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    durationMinutes: (json['durationMinutes'] as num?)?.toDouble() ?? 0,
    shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
    routePolyline: json['routePolyline'] as String? ?? '',
  );

  /// Giải mã [routePolyline] thành danh sách toạ độ để vẽ Polyline trên bản đồ.
  List<LatLng> decodedRoute() => decodePolyline(routePolyline);
}

/// Giải mã chuỗi theo "Encoded Polyline Algorithm Format" của Google
/// (Goong trả `overview_polyline.points` đúng định dạng này) → danh sách toạ độ.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
