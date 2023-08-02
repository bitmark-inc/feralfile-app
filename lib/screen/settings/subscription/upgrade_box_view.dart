// ignore_for_file: unused_element

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpgradeBoxView {
  static Widget getMoreAutonomyWidget(ThemeData theme, PremiumFeature feature,
      {bool autoClose = true, AppMetadata? peerMeta, int? id}) {
    return GetMoreAUWidget(
      feature: feature,
      autoClose: autoClose,
      id: id,
      peerMeta: peerMeta,
    );
  }
}

class GetMoreAUWidget extends StatefulWidget {
  final PremiumFeature feature;
  final bool autoClose;
  final AppMetadata? peerMeta;
  final int? id;
  const GetMoreAUWidget({
    Key? key,
    required this.feature,
    this.peerMeta,
    this.id,
    this.autoClose = true,
  }) : super(key: key);

  @override
  State<GetMoreAUWidget> createState() => _GetMoreAUWidgetState();
}

class _GetMoreAUWidgetState extends State<GetMoreAUWidget> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: UpgradesBloc(injector(), injector())..add(UpgradeQueryInfoEvent()),
      child: BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "get_more_autonomy".tr(),
                  style: theme.primaryTextTheme.ppMori700White14,
                ),
                BlocBuilder<UpgradesBloc, UpgradeState>(
                  builder: (context, state) {
                    if (_loading || state.status == IAPProductStatus.pending) {
                      _loading = false;
                      return loadingIndicator(
                          size: 20,
                          valueColor: theme.colorScheme.secondary,
                          backgroundColor:
                              theme.colorScheme.secondary.withOpacity(0.5));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                  text: "subscribe".tr(),
                  style: theme.primaryTextTheme.ppMori400Green14,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.subscriptionPage);
                      setState(() {
                        _loading = true;
                      });
                    },
                  children: [
                    TextSpan(
                      text: widget.feature.description,
                      style: theme.primaryTextTheme.ppMori400White14,
                    )
                  ]),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }
}

class _SubscribeView extends StatefulWidget {
  final PremiumFeature? feature;
  final bool autoClose;
  final AppMetadata? peerMeta;
  final int? id;

  const _SubscribeView(
      {Key? key,
      required this.feature,
      this.autoClose = true,
      this.peerMeta,
      this.id})
      : super(key: key);

  @override
  State<_SubscribeView> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<_SubscribeView> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
      if (_loading || state.status == IAPProductStatus.pending) {
        _loading = false;
        return loadingIndicator(
            size: 20,
            valueColor: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.5));
      }
      return SizedBox(
        height: 24.0,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            side: BorderSide(color: theme.colorScheme.secondary),
            // maximumSize: Size.fromHeight(30)
          ),
          onPressed: () {},
          child: Text(
            "subscribe".tr(),
            style: theme.primaryTextTheme.titleSmall,
          ),
        ),
      );
    });
  }
}
