class AnnouncementRequest {
  final int lastPullTime;
  final int offset;
  final int size;

  AnnouncementRequest(
      {required this.lastPullTime, required this.size, this.offset = 0});

  Map<String, dynamic> toJson() =>
      {'lastPullTime': lastPullTime, 'offset': offset, 'size': size};
}
