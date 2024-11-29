class FeralFileListResponse<T> {
  FeralFileListResponse({required this.result, required this.paging});

  factory FeralFileListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      FeralFileListResponse(
        result: (json['result'] as List<dynamic>)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
        paging: json['paging'] == null
            ? null
            : Paging.fromJson(Map<String, dynamic>.from(json['paging'] as Map)),
      );
  final List<T> result;
  final Paging? paging;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) => {
        'result': result.map((e) => toJson(e)).toList(),
        'paging': paging?.toJson(),
      };

  FeralFileListResponse<T> copyWith({
    List<T>? result,
    Paging? paging,
  }) =>
      FeralFileListResponse<T>(
        result: result ?? this.result,
        paging: paging ?? this.paging,
      );
}

class Paging {
  Paging({
    required this.offset,
    required this.limit,
    required this.total,
  });

  factory Paging.fromJson(Map<String, dynamic> json) => Paging(
        offset: json['offset'] as int,
        limit: json['limit'] as int,
        total: json['total'] as int,
      );
  final int offset;
  final int limit;
  final int total;

  Map<String, dynamic> toJson() => {
        'offset': offset,
        'limit': limit,
        'total': total,
      };
}

extension PagingExtension on Paging {
  bool get shouldLoadMore => offset + limit < total;
}
