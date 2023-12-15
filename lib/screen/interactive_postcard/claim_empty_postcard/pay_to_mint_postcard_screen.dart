import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: always_use_package_imports
import 'claim_empty_postcard_bloc.dart';

// ignore: always_use_package_imports
import 'claim_empty_postcard_state.dart';

class PayToMintPostcardScreen extends StatefulWidget {
  final PayToMintRequest claimRequest;

  const PayToMintPostcardScreen({required this.claimRequest, super.key});

  @override
  State<PayToMintPostcardScreen> createState() =>
      _PayToMintPostcardScreenState();
}

class _PayToMintPostcardScreenState extends State<PayToMintPostcardScreen> {
  final bloc = injector.get<ClaimEmptyPostCardBloc>();

  @override
  void initState() {
    super.initState();
    bloc.add(GetTokenEvent(widget.claimRequest));
  }

  void _handleError(final Object error) {
    if (error is DioException) {
      if (error.isPostcardClaimEmptyLimited) {
        unawaited(UIHelper.showPostcardClaimLimited(context));
        return;
      }
      final message = error.response?.data['message'];
      if (message != null && message!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ClaimEmptyPostCardBloc, ClaimEmptyPostCardState>(
          listener: (context, state) {
            if (state.error != null) {
              _handleError(state.error!);
            }
          },
          bloc: bloc,
          builder: (context, state) {
            final artwork = state.assetToken;
            if (artwork == null) {
              return Container();
            }
            return PostcardExplain(
              payload: PostcardExplainPayload(
                artwork,
                PostcardButton(
                  text: 'continue'.tr(),
                  fontSize: 18,
                  enabled: state.isClaiming != true,
                  isProcessing: state.isClaiming == true,
                  onTap: () {
                    unawaited(
                        injector<NavigationService>().selectPromptsThenStamp(
                      context,
                      state.assetToken!.copyWith(
                          owner: widget.claimRequest.address,
                          tokenId: widget.claimRequest.tokenId),
                      null,
                    ));
                  },
                  color: POSTCARD_GREEN_BUTTON_COLOR,
                ),
                isPayToMint: true,
              ),
            );
          });
}
