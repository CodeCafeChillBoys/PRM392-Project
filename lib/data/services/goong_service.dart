import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/config/goong_config.dart';
import '../models/place_suggestion.dart';
import '../models/shipping_quote.dart';

/// Gọi TRỰC TIẾP Goong REST API (không qua BE) cho phần địa chỉ:
/// - [autocomplete]: gợi ý địa chỉ khi gõ.
/// - [placeLatLng]: đổi 1 gợi ý (place_id) ra toạ độ lat/lng.
/// - [geocodeAddress]: đổi chuỗi địa chỉ đầy đủ ra toạ độ lat/lng.
/// - [directionRoute]: tuyến đường (polyline) giữa hai toạ độ.
///
/// Dùng `http` thẳng vì Goong là host ngoài (apiClient chỉ trỏ về BE).
class GoongService {
  GoongService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().length < 3) return const [];
    final uri = Uri.parse('${GoongConfig.restBase}/Place/AutoComplete').replace(
      queryParameters: {
        'api_key': GoongConfig.restApiKey,
        'input': input,
      },
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = json['predictions'] as List? ?? const [];
    return list
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  Future<LatLng?> placeLatLng(String placeId) async {
    final uri = Uri.parse('${GoongConfig.restBase}/Place/Detail').replace(
      queryParameters: {
        'api_key': GoongConfig.restApiKey,
        'place_id': placeId,
      },
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final loc = json['result']?['geometry']?['location'];
    if (loc is Map) {
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  /// Geocode một địa chỉ đầy đủ (vd địa chỉ giao hàng đã lưu trên đơn).
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final uri = Uri.parse('${GoongConfig.restBase}/Geocode').replace(
      queryParameters: {
        'api_key': GoongConfig.restApiKey,
        'address': address,
      },
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = json['results'] as List?;
    if (results == null || results.isEmpty) return null;
    final loc = (results.first as Map<String, dynamic>)['geometry']?['location'];
    if (loc is Map) {
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  /// Tuyến đường từ [origin] → [dest] (Goong Direction, vehicle=bike).
  /// Tuyến đường + thời lượng/quãng đường (leg đầu) — dùng cho màn theo dõi
  /// đơn để hiện ETA thật. [directionRoute] là wrapper giữ API cũ.
  Future<RouteResult> directionRouteDetailed(LatLng origin, LatLng dest) async {
    try {
      final uri = Uri.parse('${GoongConfig.restBase}/Direction').replace(
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${dest.latitude},${dest.longitude}',
          'vehicle': 'bike',
          'api_key': GoongConfig.restApiKey,
        },
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return RouteResult.empty;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return RouteResult.empty;
      final route0 = routes.first as Map<String, dynamic>;
      final points = route0['overview_polyline']?['points'] as String?;
      final legs = route0['legs'] as List?;
      final leg0 = (legs != null && legs.isNotEmpty)
          ? legs.first as Map<String, dynamic>
          : null;
      return RouteResult(
        points: (points == null || points.isEmpty)
            ? const []
            : decodePolyline(points),
        durationSeconds:
            ((leg0?['duration'] as Map?)?['value'] as num?)?.toInt(),
        distanceMeters:
            ((leg0?['distance'] as Map?)?['value'] as num?)?.toInt(),
      );
    } catch (_) {
      return RouteResult.empty;
    }
  }

  Future<List<LatLng>> directionRoute(LatLng origin, LatLng dest) async =>
      (await directionRouteDetailed(origin, dest)).points;
}

/// Kết quả Goong Direction: polyline + thời lượng/quãng đường tuyến.
class RouteResult {
  const RouteResult({
    required this.points,
    this.durationSeconds,
    this.distanceMeters,
  });

  final List<LatLng> points;

  /// Thời lượng tuyến (giây) — null nếu Goong không trả legs.
  final int? durationSeconds;
  final int? distanceMeters;

  static const empty = RouteResult(points: []);
}
