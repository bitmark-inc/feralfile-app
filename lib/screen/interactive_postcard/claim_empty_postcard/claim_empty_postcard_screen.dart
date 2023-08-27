import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

import 'claim_empty_postcard_bloc.dart';
import 'claim_empty_postcard_state.dart';

class ClaimEmptyPostCardScreen extends StatefulWidget {
  final RequestPostcardResponse claimRequest;

  const ClaimEmptyPostCardScreen({super.key, required this.claimRequest});

  @override
  State<ClaimEmptyPostCardScreen> createState() =>
      _ClaimEmptyPostCardScreenState();
}

class _ClaimEmptyPostCardScreenState extends State<ClaimEmptyPostCardScreen> {
  final bloc = injector.get<ClaimEmptyPostCardBloc>();

  @override
  void initState() {
    super.initState();
    bloc.add(GetTokenEvent(widget.claimRequest));
  }

  Future<void> _onStarted(BuildContext context, AssetToken assetToken) async {
    final counter = assetToken.postcardMetadata.counter;
    GeoLocation? geoLocation;
    if (counter <= 1) {
      geoLocation = moMAGeoLocation;
    } else {
      geoLocation = await getGeoLocationWithPermission();
    }
    if (!mounted || geoLocation == null) return;
    Navigator.of(context).pushNamed(AppRouter.designStamp,
        arguments: DesignStampPayload(assetToken, geoLocation));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimEmptyPostCardBloc, ClaimEmptyPostCardState>(
        listener: (context, state) {
          if (state.isClaimed == true) {
            _onStarted(context, state.assetToken!);
          }
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
              ),
            );
          }
        },
        bloc: bloc,
        builder: (context, state) {
          final artwork = state.assetToken;
          if (artwork == null) return Container();
          return PostcardExplain(
            payload: PostcardExplainPayload(
                artwork,
                PostcardButton(
                  text: "continue".tr(),
                  fontSize: 18,
                  enabled: state.isClaiming != true,
                  isProcessing: state.isClaiming == true,
                  onTap: () {
                    bloc.add(AcceptGiftEvent(widget.claimRequest));
                  },
                  color: const Color.fromRGBO(79, 174, 79, 1),
                )),
          );
        });
  }
}
