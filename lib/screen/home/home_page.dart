import 'dart:async';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uni_links/uni_links.dart';

class HomePage extends StatefulWidget {
  static const tag = "home";

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
        context.read<HomeBloc>().add(RefreshTokensEvent());
      });
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    Future.delayed(const Duration(milliseconds: 3500), () {
      context.read<HomeBloc>().add(RefreshTokensEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    context.read<HomeBloc>().add(RefreshTokensEvent());

    return Scaffold(
      body: Stack(fit: StackFit.loose, children: [
        BlocBuilder<HomeBloc, HomeState>(builder: (context, state) {
          final tokens = state.tokens;
          return SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 110,
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tokens == null || tokens.isEmpty) ...[
                    _emptyGallery(),
                  ] else ...[
                    _assetsWidget(tokens),
                  ]
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 25),
            child: GestureDetector(
              child: Image.asset("assets/images/penrose.png"),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.settingsPage),
            ),
          ),
        ),
        BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.fetchTokenState == ActionState.loading) {
              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).padding.top + 120, 20, 0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            } else {
              return SizedBox();
            }
          },
        ),
      ]),
    );
  }

  Widget _emptyGallery() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gallery",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 24.0),
            Text(
              "Your gallery is empty for now.",
              style: appTextTheme.bodyText1,
            ),
          ],
        ));
  }

  Widget _assetsWidget(List<AssetToken> tokens) {
    final groupBySource = groupBy(tokens, (AssetToken obj) => obj.source);
    final sources = groupBySource.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sources
            .map((source) => _assetsSection(
                _polishSource(source ?? ""), groupBySource[source] ?? []))
            .toList(),
      ],
    );
  }

  String _polishSource(String source) {
    switch (source) {
      case 'feralfile':
        return 'Feral File';
      case 'ArtBlocks':
        return 'Art Blocks';
      default:
        return source;
    }
  }

  Widget _assetsSection(String name, List<AssetToken> assets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            name,
            style: appTextTheme.headline1,
          ),
        ),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 3.0,
          mainAxisSpacing: 3.0,
          childAspectRatio: 1.0,
          children: List.generate(assets.length, (index) {
            final asset = assets[index];
            return GestureDetector(
              child: Container(
                child: Image.network(
                  asset.thumbnailURL!,
                  fit: BoxFit.cover,
                ),
              ),
              onTap: () {
                Navigator.of(context).pushNamed(ArtworkDetailPage.tag,
                    arguments: ArtworkDetailPayload(
                        assets.map((e) => e.id).toList(), index));
              },
            );
          }),
        ),
        SizedBox(height: 32.0),
      ],
    );
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
    if (link == null) return;
    final wcPrefix = "https://au.bitmark.com/apps/wc?uri=";
    final tzPrefix = "https://au.bitmark.com/apps/tezos?uri=";

    if (link.startsWith(wcPrefix)) {
      final wcUri = link.substring(wcPrefix.length);
      context.read<HomeBloc>().add(HomeConnectWCEvent(wcUri));
    } else if (link.startsWith(tzPrefix)) {
      final tzUri = link.substring(wcPrefix.length);
      context.read<HomeBloc>().add(HomeConnectTZEvent(tzUri));
    }
  }
}
