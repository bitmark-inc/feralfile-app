class NFTCollectionError extends Error {
  final String message;

  NFTCollectionError(this.message);

  @override
  String toString() => message;
}

class NFTCollectionClientQueryError extends NFTCollectionError {
  NFTCollectionClientQueryError({
    required this.query,
    this.variables,
    required String message,
  }) : super(message);

  final String query;
  final Map<String, dynamic>? variables;
}
