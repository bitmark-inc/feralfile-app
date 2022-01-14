import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    routeObserver.unsubscribe(this);
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
        margin:
            EdgeInsets.only(top: 64.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: BlocBuilder<HomeBloc, HomeState>(builder: (context, state) {
          return state.isFeralFileLoggedIn != null
              ? Column(
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
                    SizedBox(height: 24.0),
                    Expanded(
                      child: state.isFeralFileLoggedIn == false
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Gallery",
                                  style: Theme.of(context).textTheme.headline1,
                                ),
                                SizedBox(height: 24.0),
                                Text(
                                  "Your gallery is empty for now.",
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Feral File",
                                  style: Theme.of(context).textTheme.headline1,
                                ),
                                // SizedBox(height: 24.0),
                                GridView.count(
                                  // physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 6.0,
                                  mainAxisSpacing: 6.0,
                                  childAspectRatio: 1.0,
                                  children: List.generate(state.assets.length,
                                      (index) {
                                    return Container(
                                      child: Image.network(
                                        state.assets[index].projectMetadata
                                            .latest.thumbnailUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                    ),
                    state.isFeralFileLoggedIn == false
                        ? Row(
                            children: [
                              Expanded(
                                child: AuFilledButton(
                                  text: "Help us find your collection"
                                      .toUpperCase(),
                                  onPress: () async {
                                    dynamic uri = await Navigator.of(context)
                                        .pushNamed(ScanQRPage.tag);
                                    if (uri != null &&
                                        uri is String &&
                                        uri.startsWith("wc:")) {
                                      context
                                          .read<HomeBloc>()
                                          .add(HomeConnectWCEvent(uri));
                                    }
                                  },
                                ),
                              )
                            ],
                          )
                        : SizedBox(),
                  ],
                )
              : SizedBox();
        }),
      ),
    );
  }
}
