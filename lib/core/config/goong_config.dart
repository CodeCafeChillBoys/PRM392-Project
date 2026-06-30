/// Cấu hình Goong Maps.
///
/// - [restApiKey]: dùng cho REST API (Place AutoComplete / Place Detail / Geocode).
///   Cùng key này BE cắm vào `appsettings.json → Goong:ApiKey` để gọi Direction.
/// - [maptilesKey]: key nền bản đồ vector của Goong. Hiện màn Checkout dùng nền
///   raster OSM (ổn định, không cần plugin vector), nên key này tạm để dành —
///   sau muốn đổi nền sang Goong vector thì dùng tới (qua vector_map_tiles).
class GoongConfig {
  GoongConfig._();

  static const String restApiKey = 'VSKJ58vQTZLz7gBwKSxGsqKrEO8vElEkHXwZ5yyc';
  static const String maptilesKey = 'zkapWy2Oq5ZO9lutEt0GTTwA4DZAC2pMB4eyys8n';

  /// Base URL REST API của Goong.
  static const String restBase = 'https://rsapi.goong.io';

  /// Nền bản đồ raster cho `flutter_map` (Goong chỉ có vector tiles).
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
