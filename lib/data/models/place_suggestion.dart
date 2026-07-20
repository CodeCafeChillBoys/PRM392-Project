/// Một gợi ý địa chỉ trả về từ Goong Place AutoComplete.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description; // vd: "66 Hùng Vương, Phường 1, Quận 10, HCM"

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      PlaceSuggestion(
        placeId: json['place_id'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
