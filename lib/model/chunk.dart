import 'dart:convert';

class ChunkInfo {
  ChunkInfo({
    required this.index,
    required this.data,
    required this.total,
  });

  factory ChunkInfo.fromData(Map<String, dynamic> json) {
    final base64String = json['d'] as String;
    final chunkData = base64.decode(base64String);
    return ChunkInfo(
      index: json['i'] as int,
      data: chunkData,
      total: json['t'] as int,
    );
  }

  final int index;
  final List<int> data;
  final int total;
}
