/// Một lựa chọn địa chỉ (tỉnh / huyện / xã) cho dropdown.
/// Khớp với BE `GhnAddressItem { id, name }`.
class AddressOption {
  const AddressOption({required this.id, required this.name});

  final String id;
  final String name;

  factory AddressOption.fromJson(Map<String, dynamic> json) => AddressOption(
        id: '${json['id'] ?? ''}',
        name: json['name'] as String? ?? '',
      );

  // So sánh theo id để DropdownButton chọn đúng value.
  @override
  bool operator ==(Object other) => other is AddressOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
