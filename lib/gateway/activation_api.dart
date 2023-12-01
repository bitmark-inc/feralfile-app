import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'activation_api.g.dart';

@RestApi(baseUrl: '')
abstract class ActivationApi {
  factory ActivationApi(Dio dio, {String baseUrl}) = _ActivationApi;

  @GET('/v1/activation/{activation_id}')
  Future<ActivationInfo> getActivation(
      @Path('activation_id') String activationId);

  @POST('/v1/activation/claim')
  Future<ActivationClaimResponse> claim(@Body() ActivationClaimRequest body);
}

class ActivationInfo {
  String name;
  String description;
  String blockchain;
  String contractAddress;
  String tokenID;

  ActivationInfo(this.name, this.description, this.blockchain,
      this.contractAddress, this.tokenID);

  factory ActivationInfo.fromJson(Map<String, dynamic> json) => ActivationInfo(
        json['name'],
        json['description'],
        json['blockchain'],
        json['contractAddress'],
        json['tokenID'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'blockchain': blockchain,
        'contractAddress': contractAddress,
        'tokenID': tokenID,
      };
}

class ActivationClaimRequest {
  String activationID;
  String address;
  String airdropTOTPPasscode;

  ActivationClaimRequest(
      {required this.activationID,
      required this.address,
      required this.airdropTOTPPasscode});

  Map<String, dynamic> toJson() => {
        'activationID': activationID,
        'address': address,
        'airdropTOTPPasscode': airdropTOTPPasscode,
      };

  factory ActivationClaimRequest.fromJson(Map<String, dynamic> json) =>
      ActivationClaimRequest(
        activationID: json['activationID'],
        address: json['address'],
        airdropTOTPPasscode: json['airdropTOTPPasscode'],
      );
}

class ActivationClaimResponse {
  ActivationClaimResponse();

  factory ActivationClaimResponse.fromJson() => ActivationClaimResponse();

  Map<String, dynamic> toJson() => {};
}
