class AnnouncementRequest {
  final int lastPullTime;
  final int offset;
  final int size;

  AnnouncementRequest(
      {required this.lastPullTime, required this.offset, required this.size});

  Map<String, dynamic> toJson() =>
      {'lastPullTime': lastPullTime, 'offset': offset, 'size': size};
}
