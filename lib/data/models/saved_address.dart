/// Một địa chỉ giao hàng khách đã lưu trong "Sổ địa chỉ" (LOCAL, không cần BE).
///
/// Lưu kèm toạ độ [lat]/[lng] đã lấy sẵn từ Goong lúc thêm — nhờ vậy Checkout
/// điền lại địa chỉ này là tính được phí ship ngay, không phải geocode lại.
/// [label] là nhãn ngắn ("Nhà", "Cơ quan"…), [isDefault] đánh dấu mặc định.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  final String id;
  final String label; // "Nhà", "Cơ quan", "Người thân", "Khác"…
  final String address; // địa chỉ đầy đủ (mô tả Goong)
  final double lat;
  final double lng;
  final bool isDefault;

  SavedAddress copyWith({
    String? label,
    String? address,
    double? lat,
    double? lng,
    bool? isDefault,
  }) => SavedAddress(
    id: id,
    label: label ?? this.label,
    address: address ?? this.address,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    'lat': lat,
    'lng': lng,
    'isDefault': isDefault,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    address: json['address'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
