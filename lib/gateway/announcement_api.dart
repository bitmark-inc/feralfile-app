
import 'package:autonomy_flutter/model/announcement.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'announcement_api.g.dart';

@RestApi(baseUrl: "")
abstract class AnnouncementApi {
  factory AnnouncementApi(Dio dio, {String baseUrl}) = _AnnouncementApi;

  @POST("/announcements")
  Future<AnnouncementPostResponse> callAnnouncement();

  @GET("/announcements")
  Future<List<Announcement>> getAnnouncements({
    @Query("lastPullTime") int lastPullTime,
  });
}
