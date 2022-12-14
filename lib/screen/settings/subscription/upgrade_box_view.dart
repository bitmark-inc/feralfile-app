// ignore_for_file: unused_element

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

class UpgradeBoxView {
  static Widget getMoreAutonomyWidget(ThemeData theme, PremiumFeature feature,
      {bool autoClose = true, WCPeerMeta? peerMeta, int? id}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "get_more_autonomy".tr(),
              style: theme.primaryTextTheme.headline4,
            ),
            BlocProvider.value(
              value: UpgradesBloc(injector(), injector()),
              child: _SubscribeView(
                feature: feature,
                closeOnSubscribe: autoClose,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          feature.description,
          style: theme.primaryTextTheme.bodyText1,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SubscribeView extends StatefulWidget {
  final PremiumFeature? feature;
  final bool closeOnSubscribe;
  final WCPeerMeta? peerMeta;
  final int? id;

  const _SubscribeView(
      {Key? key,
      required this.feature,
      this.closeOnSubscribe = true,
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
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
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
          onPressed: () {
            UpgradesView.showSubscriptionDialog(
                context, state.productDetails?.price, widget.feature, (() {
              context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
              if (widget.closeOnSubscribe) {
                Navigator.of(context).pop();
              }
            }), onCancel: () {
              if (widget.peerMeta != null && widget.id != null) {
                //injector<WalletConnectService>()
                  //  .rejectRequest(widget.peerMeta!, widget.id!);
                injector<ConfigurationService>().deleteTVConnectData();
              }
              setState(
                () {
                  _loading = false;
                },
              );
            });
            setState(() {
              _loading = true;
            });
          },
          child: Text(
            "subscribe".tr(),
            style: theme.primaryTextTheme.subtitle2,
          ),
        ),
      );
    });
  }
}
