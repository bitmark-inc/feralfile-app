import 'package:autonomy_flutter/model/announcement.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'announcement_api.g.dart';

@RestApi(baseUrl: '')
abstract class AnnouncementApi {
  factory AnnouncementApi(Dio dio, {String baseUrl}) = _AnnouncementApi;

  @POST('/v1/announcements')
  Future<AnnouncementPostResponse> callAnnouncement(
      @Body() Map<String, dynamic> body);

  @GET('/v1/announcements')
  Future<List<Announcement>> getAnnouncements({
    @Query('lastPullTime') required int lastPullTime,
  });
}
