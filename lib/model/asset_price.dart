class AssetPrice {
  final String? collectedAt;
  final bool? onSale;
  final double listingPrice;
  final double purchasedPrice;
  final double minPrice;
  final String currency;
  final String? tokenID;

  AssetPrice(
      {required this.collectedAt, required this.onSale, required this.listingPrice, required this.purchasedPrice, required this.minPrice, required this.currency, this.tokenID});

  factory AssetPrice.fromJson(Map<String, dynamic> json) =>
      AssetPrice(
          collectedAt: json["collectedAt"],
          onSale: json["onSale"],
          listingPrice: json["listingPrice"].toDouble(),
          purchasedPrice: json["purchasedPrice"].toDouble(),
          minPrice: json["minPrice"].toDouble(),
          currency: json["currency"],
          tokenID: json["tokenID"]);

  Map<String, dynamic> toJson() =>
      {
        "collectedAt": collectedAt,
        "onSale": onSale,
        "listingPrice": listingPrice,
        "purchasedPrice": purchasedPrice,
        "minPrice": minPrice,
        "currency": currency,
        "tokenID": tokenID,
      };
}