import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClaimEmptyPostCardScreen extends StatefulWidget {
  final RequestPostcardResponse claimRequest;

  const ClaimEmptyPostCardScreen({required this.claimRequest, super.key});

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
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimEmptyPostCardBloc, ClaimEmptyPostCardState>(
        listener: (context, state) {
          if (state.isClaimed == true) {
            Navigator.of(context).popAndPushNamed(AppRouter.designStamp,
                arguments: DesignStampPayload(state.assetToken!));
          }
          if (state.error != null) {
            _handleError(state.error!);
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
              ),
            ),
          );
        });
  }
}
