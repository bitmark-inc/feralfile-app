import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/survey/survey.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import "package:collection/collection.dart";
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uni_links/uni_links.dart';

class HomePage extends StatefulWidget {
  static const tag = "home";

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver, AfterLayoutMixin<HomePage> {
  StreamSubscription? _deeplinkSubscription;
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  int _cachedImageSize = 0;

  @override
  void initState() {
    super.initState();
    _checkForKeySync();
    _initUniLinks();
    WidgetsBinding.instance?.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    context.read<HomeBloc>().add(RefreshTokensEvent());
    context.read<HomeBloc>().add(ReindexIndexerEvent());
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(Duration(milliseconds: 500), () {
        _handleNotificationClicked(openedResult.notification);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _cloudBackup();
    _handleForeground();
    injector<AutonomyService>().postLinkedAddresses();
    Future.delayed(Duration(seconds: 1), _handleShowingSurveys);
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
  void didPopNext() async {
    super.didPopNext();
    final connectivityResult = await (Connectivity().checkConnectivity());

    context.read<HomeBloc>().add(RefreshTokensEvent());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        context.read<HomeBloc>().add(ReindexIndexerEvent());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeBloc>().state;
    final tokens = state.tokens;

    final shouldShowMainView = tokens != null && tokens.isNotEmpty;

    final Widget assetsWidget =
        shouldShowMainView ? _assetsWidget(tokens!) : _emptyGallery();

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
        body: Stack(
          fit: StackFit.loose,
          children: [
            assetsWidget,
            PenroseTopBarView(true, _controller),
            if (state.fetchTokenState == ActionState.loading) ...[
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).padding.top + 120, 20, 0),
                  child: CupertinoActivityIndicator(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyGallery() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
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

  Widget _assetsWidget(List<AssetToken> tokens) {
    final groupByProperty = groupBy(tokens, (AssetToken obj) {
      return polishSource(obj.source ?? "Unknown");
    });

    var keys = groupByProperty.keys.toList();
    keys.sort((a, b) {
      if (a == 'Unknown') return 1;
      if (b == 'Unknown') return -1;
      if (a.startsWith('[') && !b.startsWith('[')) {
        return 1;
      } else if (!a.startsWith('[') && b.startsWith('[')) {
        return -1;
      } else {
        return a.toLowerCase().compareTo(b.toLowerCase());
      }
    });

    final tokenIDs = keys
        .map((e) => groupByProperty[e] ?? [])
        .expand((element) => element.map((e) => e.id))
        .toList();

    var sources = keys.map((sortingPropertyValue) {
      final assets = groupByProperty[sortingPropertyValue] ?? [];
      const int cellPerRow = 3;
      const double cellSpacing = 3.0;
      if (_cachedImageSize == 0) {
        final estimatedCellWidth =
            MediaQuery.of(context).size.width / cellPerRow -
                cellSpacing * (cellPerRow - 1);
        _cachedImageSize = (estimatedCellWidth * 3).ceil();
      }

      return <Widget>[
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(14, 0, 24, 14),
            child: Text(
              sortingPropertyValue,
              style: appTextTheme.headline1,
            ),
          ),
        ),
        SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cellPerRow,
              crossAxisSpacing: cellSpacing,
              mainAxisSpacing: cellSpacing,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final asset = assets[index];
                final ext = p.extension(asset.galleryThumbnailURL!);
                return GestureDetector(
                  child: Hero(
                    tag: asset.id,
                    child: ext == ".svg"
                        ? SvgPicture.network(asset.galleryThumbnailURL!)
                        : CachedNetworkImage(
                            imageUrl: asset.galleryThumbnailURL!,
                            fit: BoxFit.cover,
                            memCacheHeight: _cachedImageSize,
                            memCacheWidth: _cachedImageSize,
                            cacheManager: injector<AUCacheManager>(),
                            placeholder: (context, index) => Container(
                                color: Color.fromRGBO(227, 227, 227, 1)),
                            placeholderFadeInDuration:
                                Duration(milliseconds: 300),
                            errorWidget: (context, url, error) => Container(
                                color: Color.fromRGBO(227, 227, 227, 1),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/image_error.svg',
                                    width: 75,
                                    height: 75,
                                  ),
                                )),
                          ),
                  ),
                  onTap: () {
                    final index = tokenIDs.indexOf(asset.id);
                    final payload = ArtworkDetailPayload(tokenIDs, index);
                    if (injector<ConfigurationService>()
                        .isImmediatePlaybackEnabled()) {
                      Navigator.of(context).pushNamed(
                          AppRouter.artworkPreviewPage,
                          arguments: payload);
                    } else {
                      Navigator.of(context).push(
                        AppRouter.onGenerateRoute(RouteSettings(
                            name: AppRouter.artworkDetailsPage,
                            arguments: payload)),
                      );
                    }
                  },
                );
              },
              childCount: assets.length,
            )),
        SliverToBoxAdapter(
            child: Container(
          height: 56.0,
        ))
      ];
    }).reduce((value, element) => value += element);

    sources.insert(
        0,
        SliverToBoxAdapter(
            child: Container(
          height: 168.0,
        )));

    return CustomScrollView(
      slivers: sources,
      controller: _controller,
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

      _deeplinkSubscription = linkStream.listen(_handleDeeplink);
    } on PlatformException {}
  }

  Future<void> _checkForKeySync() async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      Navigator.of(context).pushNamed(AppRouter.keySyncPage);
    }
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

  void _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        _handleForeground();
        break;
      case FGBGType.background:
        _handleBackground();
        break;
    }
  }

  void _shouldShowNotifications(OSNotificationReceivedEvent event) {
    log.info("Receive notification: ${event.notification}");
    final data = event.notification.additionalData;
    if (data == null) return;

    switch (data['notification_type']) {
      case "customer_support_new_message":
      case "customer_support_close_issue":
        final notificationIssueID =
            '${event.notification.additionalData?['issue_id']}';
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          injector<CustomerSupportService>().triggerReloadMessages.value += 1;
          injector<CustomerSupportService>().getIssues();
          event.complete(null);
          return;
        }
        break;

      case 'gallery_new_nft':
        context.read<HomeBloc>().add(RefreshTokensEvent());
        break;
    }

    showNotifications(event.notification,
        notificationOpenedHandler: _handleNotificationClicked);
    event.complete(null);
  }

  void _handleNotificationClicked(OSNotification notification) {
    if (notification.additionalData == null) {
      // Skip handling the notification without data
      return;
    }

    log.info(
        "Tap to notification: ${notification.body ?? "empty"} \nAddtional data: ${notification.additionalData!}");

    final notificationType = notification.additionalData!["notification_type"];
    switch (notificationType) {
      case "gallery_new_nft":
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        break;

      case "customer_support_new_message":
      case "customer_support_close_issue":
        final issueID = '${notification.additionalData!["issue_id"]}';
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.supportThreadPage,
            ((route) =>
                route.settings.name == AppRouter.homePage ||
                route.settings.name == AppRouter.homePageNoTransition),
            arguments:
                DetailIssuePayload(reportIssueType: "", issueID: '$issueID'));
        break;
      default:
        log.warning("unhandled notification type: $notificationType");
        break;
    }
  }

  void _handleForeground() {
    if (injector<ConfigurationService>().isDevicePasscodeEnabled()) {
      injector<NavigationService>()
          .lockScreen()
          ?.then((_) => _deeplinkSubscription?.resume());
    } else {
      _deeplinkSubscription?.resume();
    }
    injector<ConfigurationService>().reload();
    Future.delayed(const Duration(milliseconds: 3500), () async {
      context.read<HomeBloc>().add(RefreshTokensEvent());
      context.read<HomeBloc>().add(ReindexIndexerEvent());
      await injector<AWSService>()
          .storeEventWithDeviceData("device_foreground");
    });

    injector<VersionService>().checkForUpdate();
    injector<CustomerSupportService>().getIssues();
    injector<CustomerSupportService>().processMessages();
  }

  void _handleBackground() {
    injector<AWSService>().storeEventWithDeviceData("device_background");
    injector<TokensService>().disposeIsolate();
    _deeplinkSubscription?.pause();
    _cloudBackup();
  }

  void _handleShowingSurveys() {
    const onboardingSurveyKey = "onboarding_survey";

    final finishedSurveys =
        injector<ConfigurationService>().getFinishedSurveys();
    if (finishedSurveys.contains(onboardingSurveyKey)) {
      return;
    }

    showCustomNotifications(
        "Take a 1-minute survey and be entered to win a Feral File artwork",
        Key(onboardingSurveyKey),
        notificationOpenedHandler: () =>
            Navigator.of(context).pushNamed(SurveyPage.tag, arguments: null));
  }
}
