class AddressIndex {
  AddressIndex({
    required this.address,
    required this.createdAt,
  });

  factory AddressIndex.fromJson(Map<String, dynamic> json) {
    return AddressIndex(
      address: json['address'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  String address;
  DateTime createdAt;

  @override
  bool operator ==(covariant AddressIndex other) {
    if (identical(this, other)) return true;

    return other.address == address && other.createdAt == createdAt;
  }

  @override
  int get hashCode => address.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'AddressIndex(address: $address, createdAt: $createdAt)';

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
