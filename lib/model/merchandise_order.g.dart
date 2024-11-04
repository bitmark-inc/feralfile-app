// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchandise_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchandiseOrder _$MerchandiseOrderFromJson(Map<String, dynamic> json) =>
    MerchandiseOrder(
      id: json['id'] as String,
      paymentStatus: json['payment_status'] as String,
      orderStatus: json['order_status'] as String,
      data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MerchandiseOrderToJson(MerchandiseOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'payment_status': instance.paymentStatus,
      'order_status': instance.orderStatus,
      'data': instance.data,
    };

OrderData _$OrderDataFromJson(Map<String, dynamic> json) => OrderData(
      items: (json['items'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      token: MerchandiseToken.fromJson(json['token'] as Map<String, dynamic>),
      recipient: Recipient.fromJson(json['recipient'] as Map<String, dynamic>),
      totalCosts: (json['total_costs'] as num).toDouble(),
      shippingFee: (json['shipping_fee'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderDataToJson(OrderData instance) => <String, dynamic>{
      'items': instance.items,
      'token': instance.token,
      'recipient': instance.recipient,
      'total_costs': instance.totalCosts,
      'shipping_fee': instance.shippingFee,
    };

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      variant: Variant.fromJson(json['variant'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'variant': instance.variant,
      'quantity': instance.quantity,
    };

Variant _$VariantFromJson(Map<String, dynamic> json) => Variant(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VariantToJson(Variant instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'product': instance.product,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrls: (json['image_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_urls': instance.imageUrls,
      'description': instance.description,
    };

MerchandiseToken _$MerchandiseTokenFromJson(Map<String, dynamic> json) =>
    MerchandiseToken(
      indexId: json['index_id'] as String,
      imageUrls: (json['image_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      previewUrl: json['preview_url'] as String,
    );

Map<String, dynamic> _$MerchandiseTokenToJson(MerchandiseToken instance) =>
    <String, dynamic>{
      'index_id': instance.indexId,
      'image_urls': instance.imageUrls,
      'preview_url': instance.previewUrl,
    };

Recipient _$RecipientFromJson(Map<String, dynamic> json) => Recipient(
      zip: json['zip'] as String,
      city: json['city'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      company: json['company'] as String,
      addressOne: json['address1'] as String,
      addressTwo: json['address2'] as String,
      stateCode: json['state_code'] as String,
      stateName: json['state_name'] as String,
      taxNumber: json['tax_number'] as String,
      countryCode: json['country_code'] as String,
      countryName: json['country_name'] as String,
    );

Map<String, dynamic> _$RecipientToJson(Recipient instance) => <String, dynamic>{
      'zip': instance.zip,
      'city': instance.city,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'company': instance.company,
      'address1': instance.addressOne,
      'address2': instance.addressTwo,
      'state_code': instance.stateCode,
      'state_name': instance.stateName,
      'tax_number': instance.taxNumber,
      'country_code': instance.countryCode,
      'country_name': instance.countryName,
    };
