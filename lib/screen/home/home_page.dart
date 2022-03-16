import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import "package:collection/collection.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uni_links/uni_links.dart';
import 'package:path/path.dart' as p;

class HomePage extends StatefulWidget {
  static const tag = "home";

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {
  StreamSubscription? _deeplinkSubscription;
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  int _cachedImageSize = 0;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    _cloudBackup();
    WidgetsBinding.instance?.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    context.read<HomeBloc>().add(RefreshTokensEvent());
    context.read<HomeBloc>().add(ReindexIndexerEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cloudBackup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    routeObserver.unsubscribe(this);
    _deeplinkSubscription?.cancel();
    _fgbgSubscription?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    Future.delayed(const Duration(milliseconds: 1000), () {
      context.read<HomeBloc>().add(RefreshTokensEvent());
      context.read<HomeBloc>().add(ReindexIndexerEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocBuilder<HomeBloc, HomeState>(builder: (context, state) {
      final tokens = state.tokens;
      final shouldShowMainView = tokens != null && tokens.isNotEmpty;
      final ListView assetsWidget =
          shouldShowMainView ? _assetsWidget(tokens!) : _emptyGallery();

      return Stack(fit: StackFit.loose, children: [
        shouldShowMainView ? assetsWidget : _emptyGallery(),
        PenroseTopBarView(true, _controller),
        BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.fetchTokenState == ActionState.loading) {
              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).padding.top + 120, 20, 0),
                  child: CupertinoActivityIndicator(),
                ),
              );
            } else {
              return SizedBox();
            }
          },
        ),
      ]);
    }));
  }

  ListView _emptyGallery() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      controller: _controller,
      children: [
        SizedBox(height: 160),
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
    );
  }

  ListView _assetsWidget(List<AssetToken> tokens) {
    final groupBySource = groupBy(tokens, (AssetToken obj) => obj.source);
    var sources = groupBySource.keys.map((source) {
      final assets = groupBySource[source] ?? [];
      const int cellPerRow = 3;
      const double cellSpacing = 3.0;
      if (_cachedImageSize == 0) {
        final estimatedCellWidth =
            MediaQuery.of(context).size.width / cellPerRow -
                cellSpacing * (cellPerRow - 1);
        _cachedImageSize = (estimatedCellWidth * 3).ceil();
      }
      return <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: Text(
            polishSource(source ?? ""),
            style: appTextTheme.headline1,
          ),
        ),
        GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cellPerRow,
              crossAxisSpacing: cellSpacing,
              mainAxisSpacing: cellSpacing,
              childAspectRatio: 1.0,
            ),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            padding: EdgeInsets.symmetric(vertical: 24),
            itemCount: assets.length,
            itemBuilder: (BuildContext context, int index) {
              final asset = assets[index];
              final ext = p.extension(asset.thumbnailURL!);
              return GestureDetector(
                child: Container(
                  child: ext == ".svg"
                      ? SvgPicture.network(asset.thumbnailURL!)
                      : CachedNetworkImage(
                          imageUrl: asset.thumbnailURL!,
                          fit: BoxFit.cover,
                          maxHeightDiskCache: _cachedImageSize,
                          maxWidthDiskCache: _cachedImageSize,
                          memCacheHeight: _cachedImageSize,
                          memCacheWidth: _cachedImageSize,
                          placeholder: (context, index) => Container(
                              color: Color.fromRGBO(227, 227, 227, 1)),
                          placeholderFadeInDuration:
                              Duration(milliseconds: 300),
                          errorWidget: (context, url, error) =>
                              SizedBox(height: 100),
                        ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(ArtworkDetailPage.tag,
                      arguments: ArtworkDetailPayload(
                          assets.map((e) => e.id).toList(), index));
                },
              );
            }),
        SizedBox(height: 32.0),
      ];
    }).reduce((value, element) => value += element);

    sources.insert(0, SizedBox(height: 108));

    return ListView(
      children: sources,
      controller: _controller,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
  }

  Future<void> _cloudBackup() async {
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase();
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

    final wcPrefixes = [
      "https://au.bitmark.com/apps/wc?uri=",
      "https://au.bitmark.com/apps/wc/wc?uri=", // maybe something wrong with WC register; fix by this for now
      "https://autonomy.io/apps/wc?uri=",
      "https://autonomy.io/apps/wc/wc?uri=",
    ];

    final tzPrefixes = [
      "https://au.bitmark.com/apps/tezos?uri=",
      "https://autonomy.io/apps/tezos?uri=",
    ];

    final wcDeeplinkPrefixes = [
      'wc:',
      'autonomy-wc:',
    ];

    final tbDeeplinkPrefixes = [
      "tezos://",
      "autonomy-tezos://",
    ];

    // Check Universal Link
    final callingWCPrefix =
        wcPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCPrefix != null) {
      final wcUri = link.substring(callingWCPrefix.length);
      final decodedWcUri = Uri.decodeFull(wcUri);
      context.read<HomeBloc>().add(HomeConnectWCEvent(decodedWcUri));
      return;
    }

    final callingTBPrefix =
        tzPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBPrefix != null) {
      final tzUri = link.substring(callingTBPrefix.length);
      context.read<HomeBloc>().add(HomeConnectTZEvent(tzUri));
      return;
    }

    final callingWCDeeplinkPrefix = wcDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCDeeplinkPrefix != null) {
      context.read<HomeBloc>().add(HomeConnectWCEvent(link));
      return;
    }

    final callingTBDeeplinkPrefix = tbDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBDeeplinkPrefix != null) {
      context.read<HomeBloc>().add(HomeConnectTZEvent(link));
      return;
    }
  }

  void _handleForeBackground(FGBGType event) {
    switch (event) {
      case FGBGType.foreground:
        if (injector<ConfigurationService>().isDevicePasscodeEnabled()) {
          injector<NavigationService>().lockScreen();
        }
        injector<ConfigurationService>().reload();
        Future.delayed(const Duration(milliseconds: 3500), () async {
          context.read<HomeBloc>().add(RefreshTokensEvent());
          context.read<HomeBloc>().add(ReindexIndexerEvent());
          await injector<AWSService>()
              .storeEventWithDeviceData("device_foreground");
        });
        break;
      case FGBGType.background:
        injector<AWSService>().storeEventWithDeviceData("device_background");
        break;
    }
  }
}
