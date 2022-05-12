import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

class TVConnectPage extends StatefulWidget {
  final WCConnectPageArgs wcConnectArgs;

  const TVConnectPage({Key? key, required this.wcConnectArgs})
      : super(key: key);

  @override
  State<TVConnectPage> createState() => _TVConnectPageState();
}

class _TVConnectPageState extends State<TVConnectPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    context.read<PersonaBloc>().add(GetListPersonaEvent());
    injector<NavigationService>().setIsWCConnectInShow(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context.read<PersonaBloc>().add(GetListPersonaEvent());
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    injector<NavigationService>().setIsWCConnectInShow(false);
  }

  void _reject() {
    final wcConnectArgs = widget.wcConnectArgs;
    if (wcConnectArgs != null) {
      injector<WalletConnectService>().rejectSession(wcConnectArgs.peerMeta);
    }

    Navigator.of(context).pop();
  }

  Future _approve(List<String> addresses) async {
    if (addresses.isEmpty) return;

    final chainId =
    injector<ConfigurationService>().getNetwork() == Network.MAINNET
        ? 1
        : 4;

    var approvedAddresses = addresses;
    log.info(
        "[WCConnectPage] approve WCConnect with addreses $approvedAddresses");

    final jwt = await injector<AuthService>().getAuthToken(forceRefresh: true);
    approvedAddresses.add(jwt.jwtToken);

    await injector<WalletConnectService>()
        .approveSession(Uuid().v4(), widget.wcConnectArgs.peerMeta, approvedAddresses, chainId);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    final appTextTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: SizedBox(),
        leadingWidth: 0.0,
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _reject(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
                child: Row(
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/nav-arrow-left.svg',
                          color: Colors.white,
                        ),
                        SizedBox(width: 7),
                        Text(
                          "BACK",
                          style: appTextTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Connect to Autonomy Viewer",
            style: appTextTheme.headline1,
          ),
          SizedBox(height: 24),
          Text(
              "Instantly set up your personal NFT art gallery on TVs and projectors anywhere you go.",
              style: appTextTheme.bodyText1),
          Divider(
            height: 64,
            color: Colors.white,
          ),
          Text("Autonomy Viewer is requesting to: ",
              style: appTextTheme.bodyText1),
          SizedBox(height: 8),
          Text("• View your Autonomy NFT collections",
              style: appTextTheme.bodyText1),
          Expanded(child: SizedBox()),
          BlocListener<AccountsBloc, AccountsState>(
            listener: (context, state) {
              final event = state.event;
              if (event == null) return;

              // Approve for Autonomy TV
              if (event is FetchAllAddressesSuccessEvent) {
                _approve(event.addresses);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Authorize".toUpperCase(),
                    onPress: () {
                      context
                          .read<AccountsBloc>()
                          .add(FetchAllAddressesEvent());
                    },
                    color: theme.primaryColor,
                    textStyle: TextStyle(
                        color: theme.backgroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                  ),
                )
              ],
            ),
          )
        ]),
      ),
    );
  }
}
