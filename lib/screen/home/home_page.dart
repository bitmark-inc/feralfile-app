import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uni_links/uni_links.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {
  StreamSubscription? _deeplinkSubscription;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    routeObserver.unsubscribe(this);
    _deeplinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        context.read<HomeBloc>().add(HomeCheckFeralFileLoginEvent());
      });
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    Future.delayed(const Duration(milliseconds: 3500), () {
      context.read<HomeBloc>().add(HomeCheckFeralFileLoginEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    context.read<HomeBloc>().add(HomeCheckFeralFileLoginEvent());

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 64.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              child: Center(
                child: Image.asset("assets/images/penrose.png"),
              ),
              onTap: () {
                Navigator.of(context).pushNamed(SettingsPage.tag);
              },
            ),
            Expanded(
              child:
                  BlocBuilder<HomeBloc, HomeState>(builder: (context, state) {
                return state.isFeralFileLoggedIn != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24.0),
                          Expanded(
                            child: state.isFeralFileLoggedIn == false ||
                                    _isAssetsEmpty(state)
                                ? Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Gallery",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline1,
                                        ),
                                        SizedBox(height: 24.0),
                                        Text(
                                          "Your gallery is empty for now.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1,
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      state.ffAssets.isNotEmpty
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                                  child: Text(
                                                    "Feral File",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline1,
                                                  ),
                                                ),
                                                GridView.count(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 3.0,
                                                  mainAxisSpacing: 3.0,
                                                  childAspectRatio: 1.0,
                                                  children: List.generate(
                                                      state.ffAssets.length,
                                                      (index) {
                                                    final asset =
                                                        state.ffAssets[index];
                                                    return GestureDetector(
                                                      child: Container(
                                                        child: Image.network(
                                                          asset.thumbnailURL!,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.of(context).pushNamed(
                                                            ArtworkDetailPage
                                                                .tag,
                                                            arguments: ArtworkDetailPayload(
                                                                state.ffAssets
                                                                    .map((e) =>
                                                                        e.id)
                                                                    .toList(),
                                                                index));
                                                      },
                                                    );
                                                  }),
                                                ),
                                                SizedBox(height: 16.0),
                                              ],
                                            )
                                          : SizedBox(),
                                      state.ethAssets.isNotEmpty
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 16.0,
                                                      right: 16.0,
                                                      top: 16.0),
                                                  child: Text(
                                                    "Opensea",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline1,
                                                  ),
                                                ),
                                                GridView.count(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 3.0,
                                                  mainAxisSpacing: 3.0,
                                                  childAspectRatio: 1.0,
                                                  children: List.generate(
                                                      state.ethAssets.length,
                                                      (index) {
                                                    final asset =
                                                        state.ethAssets[index];
                                                    return GestureDetector(
                                                      child: Container(
                                                        child: Image.network(
                                                          asset.thumbnailURL!,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.of(context).pushNamed(
                                                            ArtworkDetailPage
                                                                .tag,
                                                            arguments: ArtworkDetailPayload(
                                                                state.ethAssets
                                                                    .map((e) =>
                                                                        e.id)
                                                                    .toList(),
                                                                index));
                                                      },
                                                    );
                                                  }),
                                                ),
                                                SizedBox(height: 16.0),
                                              ],
                                            )
                                          : SizedBox(),
                                      state.xtzAssets.isNotEmpty
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 16.0,
                                                      right: 16.0,
                                                      top: 16.0),
                                                  child: Text(
                                                    "Tezos",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline1,
                                                  ),
                                                ),
                                                GridView.count(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 3.0,
                                                  mainAxisSpacing: 3.0,
                                                  childAspectRatio: 1.0,
                                                  children: List.generate(
                                                      state.xtzAssets.length,
                                                      (index) {
                                                    final asset =
                                                        state.xtzAssets[index];

                                                    return GestureDetector(
                                                      child: Container(
                                                        child: Image.network(
                                                          asset.thumbnailURL!,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.of(context).pushNamed(
                                                            ArtworkDetailPage
                                                                .tag,
                                                            arguments: ArtworkDetailPayload(
                                                                state.xtzAssets
                                                                    .map((e) =>
                                                                        e.id)
                                                                    .toList(),
                                                                index));
                                                      },
                                                    );
                                                  }),
                                                ),
                                                SizedBox(height: 16.0),
                                              ],
                                            )
                                          : SizedBox(),
                                    ],
                                  ),
                          ),
                          state.isFeralFileLoggedIn == false
                              ? Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AuFilledButton(
                                          text: "Help us find your collection"
                                              .toUpperCase(),
                                          onPress: () {
                                            Navigator.of(context).pushNamed(
                                                ScanQRPage.tag,
                                                arguments: ScannerItem.GLOBAL);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : SizedBox(),
                        ],
                      )
                    : SizedBox();
              }),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAssetsEmpty(HomeState state) {
    return state.xtzAssets.isEmpty &&
        state.ffAssets.isEmpty &&
        state.ethAssets.isEmpty;
  }

  Future<void> _initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      _handleDeeplink(initialLink);

      _deeplinkSubscription = linkStream.listen((String? link) {
        _handleDeeplink(link);
      }, onError: (err) {});
    } on PlatformException {}
  }

  void _handleDeeplink(String? link) {
    final prefix = "https://au.bitmark.com/apps/wc?uri=";
    if (link != null && link.startsWith(prefix)) {
      final wcUri = link.substring(prefix.length);
      context.read<HomeBloc>().add(HomeConnectWCEvent(wcUri));
    }
  }
}
