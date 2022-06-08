import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpgradeBoxView {
  static Widget getMoreAutonomyWidget(ThemeData theme, PremiumFeature feature) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Get more Autonomy",
              style: theme.textTheme.headline4,
            ),
            BlocProvider.value(
              value: UpgradesBloc(injector(), injector()),
              child: _SubscribeView(feature: feature),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          feature.description,
          style: theme.textTheme.bodyText1,
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class _SubscribeView extends StatefulWidget {
  final PremiumFeature? feature;

  const _SubscribeView({Key? key, required this.feature}) : super(key: key);

  @override
  State<_SubscribeView> createState() => _SubscribeViewState();
}

class _SubscribeViewState extends State<_SubscribeView> {
  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
    return BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
      return Container(
          height: 24.0,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // <-- Radius
                ),
                side: BorderSide(width: 1.0, color: Colors.white),
                // maximumSize: Size.fromHeight(30)
              ),
              onPressed: () => UpgradesView.showSubscriptionDialog(
                      context, state.productDetails?.price, widget.feature,
                      (() {
                    context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
                    Navigator.of(context).pop();
                  })),
              child: Text(
                "SUBSCRIBE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    fontFamily: "IBMPlexMono"),
              )));
    });
  }
}
