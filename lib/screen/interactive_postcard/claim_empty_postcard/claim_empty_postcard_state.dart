// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:nft_collection/models/models.dart';

abstract class ClaimEmptyPostCardEvent {}

class ClaimEmptyPostCardState {
  final AssetToken? assetToken;
  final bool? isClaiming;
  final bool? isClaimed;
  final String? error;

  ClaimEmptyPostCardState({
    this.assetToken,
    this.isClaiming,
    this.isClaimed,
    this.error,
  });

  ClaimEmptyPostCardState copyWith({
    AssetToken? assetToken,
    bool? isClaiming,
    bool? isClaimed,
    String? error,
  }) {
    return ClaimEmptyPostCardState(
      assetToken: assetToken ?? this.assetToken,
      isClaiming: isClaiming ?? this.isClaiming,
      isClaimed: isClaimed ?? this.isClaimed,
      error: error,
    );
  }
}

class GetTokenEvent extends ClaimEmptyPostCardEvent {
  final RequestPostcardResponse claimRequest;

  // constructor
  GetTokenEvent(this.claimRequest);
}

class AcceptGiftEvent extends ClaimEmptyPostCardEvent {
  final RequestPostcardResponse claimRequest;

  // constructor
  AcceptGiftEvent(this.claimRequest);
}
