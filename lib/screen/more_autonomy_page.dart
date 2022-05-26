import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MoreAutonomyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<UpgradesBloc, UpgradeState>(
        listener: (context, state) {
          if (state.status == IAPProductStatus.completed ||
              state.status == IAPProductStatus.error) {
            Navigator.of(context).pushNamed(AppRouter.newAccountPage);
          }
        },
        builder: (context, state) {
          return Container(
            margin: EdgeInsets.only(
                top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("More Autonomy", style: appTextTheme.headline1),
                SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/images/premium_comparation_light.svg',
                  height: 320,
                ),
                SizedBox(height: 16),
                Text(
                    "*Coming in May: View your collection on TVs and projectors. Preserve and authentificate your artworks for the long-term.",
                    style: appTextTheme.headline5),
                Expanded(child: SizedBox()),
                AuFilledButton(
                  text:
                      "SUBSCRIBE FOR ${state.productDetails?.price ?? "4.99"}/MONTH",
                  onPress: state.status == IAPProductStatus.loading ||
                          state.status == IAPProductStatus.pending
                      ? null
                      : () {
                          context
                              .read<UpgradesBloc>()
                              .add(UpgradePurchaseEvent());
                        },
                  textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: "IBMPlexMono"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.newAccountPage),
                  child: Text(
                    "NOT NOW",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
