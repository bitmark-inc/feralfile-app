import 'package:json_annotation/json_annotation.dart';

part 'merchandise_order.g.dart';

@JsonSerializable()
class MerchandiseOrder {
  final String id;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'order_status')
  final String orderStatus;
  @JsonKey(name: 'data')
  final OrderData data;

  MerchandiseOrder({
    required this.id,
    required this.paymentStatus,
    required this.orderStatus,
    required this.data,
  });

  factory MerchandiseOrder.fromJson(Map<String, dynamic> json) =>
      _$MerchandiseOrderFromJson(json);

  Map<String, dynamic> toJson() => _$MerchandiseOrderToJson(this);
}

@JsonSerializable()
class OrderData {
  final List<Item> items;
  final Token token;
  final Recipient recipient;
  @JsonKey(name: 'total_costs')
  final double totalCosts;
  @JsonKey(name: 'shipping_fee')
  final double shippingFee;

  OrderData({
    required this.items,
    required this.token,
    required this.recipient,
    required this.totalCosts,
    required this.shippingFee,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) =>
      _$OrderDataFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDataToJson(this);
}

@JsonSerializable()
class Item {
  final Variant variant;
  final int quantity;

  Item({
    required this.variant,
    required this.quantity,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable()
class Variant {
  final String id;
  final String name;
  final double price;
  final Product product;

  Variant({
    required this.id,
    required this.name,
    required this.price,
    required this.product,
  });

  factory Variant.fromJson(Map<String, dynamic> json) =>
      _$VariantFromJson(json);

  Map<String, dynamic> toJson() => _$VariantToJson(this);
}

@JsonSerializable()
class Product {
  final String id;
  final String name;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class Token {
  @JsonKey(name: 'index_id')
  final String indexId;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @JsonKey(name: 'preview_url')
  final String previewUrl;

  Token({
    required this.indexId,
    required this.imageUrl,
    required this.previewUrl,
  });

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);
}

@JsonSerializable()
class Recipient {
  final String zip;
  final String city;
  final String name;
  final String email;
  final String phone;
  final String company;
  @JsonKey(name: 'address1')
  final String addressOne;
  @JsonKey(name: 'address2')
  final String addressTwo;
  @JsonKey(name: 'state_code')
  final String stateCode;
  @JsonKey(name: 'state_name')
  final String stateName;
  @JsonKey(name: 'tax_number')
  final String taxNumber;
  @JsonKey(name: 'country_code')
  final String countryCode;
  @JsonKey(name: 'country_name')
  final String countryName;

  Recipient({
    required this.zip,
    required this.city,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.addressOne,
    required this.addressTwo,
    required this.stateCode,
    required this.stateName,
    required this.taxNumber,
    required this.countryCode,
    required this.countryName,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) =>
      _$RecipientFromJson(json);

  Map<String, dynamic> toJson() => _$RecipientToJson(this);
}

class MerchandiseOrderResponse {
  final MerchandiseOrder order;

  MerchandiseOrderResponse({
    required this.order,
  });

  factory MerchandiseOrderResponse.fromJson(Map<String, dynamic> json) =>
      MerchandiseOrderResponse(
        order: MerchandiseOrder.fromJson(json['order']),
      );

  Map<String, dynamic> toJson() => {
        'order': order.toJson(),
      };
}
