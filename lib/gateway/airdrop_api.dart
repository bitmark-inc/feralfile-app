import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'airdrop_api.g.dart';

@RestApi(baseUrl: '')
abstract class AirdropApi {
  factory AirdropApi(Dio dio, {String baseUrl}) = _AirdropApi;

  @POST('/v1/claim/request')
  Future<AirdropRequestClaimResponse> requestClaim(
      @Body() AirdropRequestClaimRequest body);

  @POST('/v1/claim')
  Future<TokenClaimResponse> claim(@Body() AirdropClaimRequest body);

  @GET('/v1/claim/{share_code}')
  Future<AirdropClaimShareResponse> claimShare(
      @Path('share_code') String shareCode);

  @POST('/v1/share/{token_id}')
  Future<AirdropShareResponse> share(
      @Path('token_id') String tokenId, @Body() AirdropShareRequest body);
}
