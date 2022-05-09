import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'customer_support_api.g.dart';

@RestApi(baseUrl: "")
abstract class CustomerSupportApi {
  factory CustomerSupportApi(Dio dio, {String baseUrl}) = _CustomerSupportApi;

  @GET("/v1/issues")
  Future<List<Issue>> getIssues();

  @GET("/v1/issues/{issueID}")
  Future<IssueDetails> getDetails(
    @Path("issueID") String issueID, {
    @Query("reverse") bool reverse = true,
  });

  @POST("/v1/issues/")
  Future<PostedMessageResponse> createIssue(
    @Body() Map<String, Object> body,
  );

  @POST("/v1/issues/{issueID}")
  Future<PostedMessageResponse> commentIssue(
    @Path("issueID") String issueID,
    @Body() Map<String, Object> body,
  );

  @PATCH("/v1/issues/{issueID}/reopen")
  Future reOpenIssue(
    @Path("issueID") String issueID,
  );
}
