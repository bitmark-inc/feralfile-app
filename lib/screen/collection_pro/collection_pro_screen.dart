import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_screen.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:autonomy_flutter/util/predefined_collection_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/carousel.dart';
import 'package:autonomy_flutter/view/galery_thumbnail_item.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/searchBar.dart';
import 'package:autonomy_flutter/view/tip_card.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/predefined_collection_model.dart';
import 'package:open_settings/open_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectionPro extends StatefulWidget {
  final List<CompactedAssetToken> tokens;
  final ScrollController scrollController;

  const CollectionPro(
      {super.key, required this.tokens, required this.scrollController});

  @override
  State<CollectionPro> createState() => CollectionProState();
}

class CollectionProState extends State<CollectionPro>
    with RouteAware, WidgetsBindingObserver {
  final _bloc = injector.get<CollectionProBloc>();
  final _identityBloc = injector.get<IdentityBloc>();
  final _configurationService = injector.get<ConfigurationService>();
  late ScrollController _scrollController;
  late ValueNotifier<String> searchStr;
  late bool isShowSearchBar;
  late bool isShowFullHeader;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    searchStr = ValueNotifier('');
    searchStr.addListener(() {
      loadCollection();
    });
    isShowSearchBar = false;
    isShowFullHeader = true;
    _scrollController = widget.scrollController;
    _scrollController.addListener(_scrollListenerShowfullHeader);
    loadCollection();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  dispose() {
    _scrollController.removeListener(_scrollListenerShowfullHeader);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  _scrollListenerShowfullHeader() {
    if (_scrollController.offset > 50 && isShowSearchBar) {
      if (isShowFullHeader) {
        setState(() {
          isShowFullHeader = false;
        });
      }
    } else {
      if (!isShowFullHeader) {
        setState(() {
          isShowFullHeader = true;
        });
      }
    }
  }

  loadCollection() {
    _bloc.add(LoadCollectionEvent(filterStr: searchStr.value));
  }

  fetchIdentities(CollectionLoadedState state) {
    final listPredefinedCollectionByArtist =
        state.listPredefinedCollectionByArtist;
    final neededIdentities = [
      ...?listPredefinedCollectionByArtist?.map((e) => e.id).toList(),
    ].whereNotNull().toList().unique();
    neededIdentities.removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      _identityBloc.add(GetIdentityEvent(neededIdentities));
    }
  }

  Widget _carouselTipcard(BuildContext context) {
    return MultiValueListenableBuilder(
      valueListenables: [
        _configurationService.showTvAppTip,
        _configurationService.showCreatePlaylistTip,
        _configurationService.showLinkOrImportTip,
        _configurationService.showBackupSettingTip,
      ],
      builder: (BuildContext context, List<dynamic> values, Widget? child) {
        return CarouselWithIndicator(
          items: _listTipcards(context, values),
        );
      },
    );
  }

  List<Tipcard> _listTipcards(BuildContext context, List<dynamic> values) {
    final theme = Theme.of(context);
    final isShowTvAppTip = values[0] as bool;
    final isShowCreatePlaylistTip = values[1] as bool;
    final isShowLinkOrImportTip = values[2] as bool;
    final isShowBackupSettingTip = values[3] as bool;
    return [
      if (isShowLinkOrImportTip)
        Tipcard(
            titleText: "do_you_have_NFTs_in_other_wallets".tr(),
            onPressed: () {},
            buttonText: "add_wallet".tr(),
            content: Text("you_can_link_or_import".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showLinkOrImportTip),
      if (isShowCreatePlaylistTip)
        Tipcard(
            titleText: "create_your_first_playlist".tr(),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.createPlayListPage);
            },
            buttonText: "create_new_playlist".tr(),
            content: Text("as_a_pro_sub_playlist".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showCreatePlaylistTip),
      if (isShowTvAppTip)
        Tipcard(
            titleText: "enjoy_your_collection".tr(),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.scanQRPage,
                arguments: ScannerItem.GLOBAL,
              );
            },
            buttonText: "sync_up_with_autonomy_tv".tr(),
            content: RichText(
              text: TextSpan(
                text: "as_a_pro_sub_TV_app".tr(),
                style: theme.textTheme.ppMori400Black14,
                children: [
                  TextSpan(
                    text: "google_TV_app".tr(),
                    style: theme.textTheme.ppMori400Black14.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final metricClient = injector<MetricClientService>();
                        metricClient.addEvent(MixpanelEvent.tapLinkInTipCard,
                            data: {
                              "link": TV_APP_STORE_URL,
                              "title": "enjoy_your_collection".tr()
                            });
                        launchUrl(Uri.parse(TV_APP_STORE_URL),
                            mode: LaunchMode.externalApplication);
                      },
                  ),
                  TextSpan(
                    text: "currently_available_on".tr(),
                  )
                ],
              ),
            ),
            listener: _configurationService.showTvAppTip),
      if (isShowBackupSettingTip)
        Tipcard(
            titleText: "backup_failed".tr(),
            onPressed: Platform.isAndroid
                ? () {
                    OpenSettings.openAddAccountSetting();
                  }
                : () async {
                    openAppSettings();
                  },
            buttonText: Platform.isAndroid
                ? "open_device_setting".tr()
                : "open_icloud_setting".tr(),
            content: Text(
                Platform.isAndroid
                    ? "backup_tip_card_content_android".tr()
                    : "backup_tip_card_content_ios".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showBackupSettingTip),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer(
        bloc: _bloc,
        listener: (context, state) {
          if (state is CollectionLoadedState) {
            fetchIdentities(state);
          }
        },
        builder: (context, collectionProState) {
          if (collectionProState is CollectionLoadedState) {
            final listPredefinedCollectionByMedium =
                collectionProState.listPredefinedCollectionByMedium;

            final works = collectionProState.works;
            final paddingTop = MediaQuery.of(context).viewPadding.top;
            return BlocBuilder<IdentityBloc, IdentityState>(
                builder: (context, identityState) {
                  final identityMap = identityState.identityMap
                    ..removeWhere((key, value) => value.isEmpty);
                  final listPredefinedCollectionByArtist =
                      collectionProState.listPredefinedCollectionByArtist
                          ?.map(
                            (e) {
                              final name = identityMap[e.id] ?? e.name ?? e.id;
                              e.name = name;
                              return e;
                            },
                          )
                          .toList()
                          .filterByName(searchStr.value);
                  return Scaffold(
                    body: Stack(
                      children: [
                        CustomScrollView(
                          shrinkWrap: true,
                          slivers: [
                            SliverAppBar(
                              pinned: isShowSearchBar,
                              centerTitle: true,
                              backgroundColor: Colors.white,
                              expandedHeight: isShowFullHeader ? 126 : 75,
                              collapsedHeight: isShowFullHeader ? 126 : 75,
                              shadowColor: Colors.transparent,
                              flexibleSpace: Column(
                                children: [
                                  if (isShowFullHeader) ...[
                                    headDivider(),
                                    const SizedBox(height: 22),
                                  ],
                                  SizedBox(
                                    height: 50,
                                    child: !isShowSearchBar
                                        ? HeaderView(
                                            paddingTop: paddingTop,
                                            action: GestureDetector(
                                              child: SvgPicture.asset(
                                                "assets/images/search.svg",
                                                width: 24,
                                                height: 24,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                        AppColor.primaryBlack,
                                                        BlendMode.srcIn),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  isShowSearchBar = true;
                                                });
                                              },
                                            ),
                                          )
                                        : Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15),
                                              child: ActionBar(
                                                searchBar: AuSearchBar(
                                                  onChanged: (text) {},
                                                  onSearch: (text) {
                                                    setState(() {
                                                      searchStr.value = text;
                                                    });
                                                  },
                                                  onClear: (text) {
                                                    setState(() {
                                                      searchStr.value = text;
                                                    });
                                                  },
                                                ),
                                                onCancel: () {
                                                  setState(() {
                                                    searchStr.value = '';
                                                    isShowSearchBar = false;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 23),
                                  addOnlyDivider(
                                      color: AppColor.auQuickSilver,
                                      border: 0.25)
                                ],
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: _carouselTipcard(context),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                            if (searchStr.value.isEmpty) ...[
                              SliverToBoxAdapter(
                                child: PredefinedCollectionSection(
                                  listPredefinedCollection:
                                      listPredefinedCollectionByMedium ?? [],
                                  predefinedCollectionType:
                                      PredefinedCollectionType.medium,
                                  searchStr: searchStr.value,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 60),
                              ),
                            ],
                            if (searchStr.value.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: WorksSection(
                                  works: works,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 60),
                              ),
                            ],
                            SliverToBoxAdapter(
                              child: PredefinedCollectionSection(
                                listPredefinedCollection:
                                    listPredefinedCollectionByArtist ?? [],
                                predefinedCollectionType:
                                    PredefinedCollectionType.artist,
                                searchStr: searchStr.value,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                bloc: _identityBloc);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget? icon;
  final Function()? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subTitle,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        if (subTitle != null)
          Text(
            subTitle!,
            style: theme.textTheme.ppMori400Black14,
          ),
        if (icon != null) ...[
          const SizedBox(width: 15),
          GestureDetector(onTap: onTap, child: icon!)
        ],
      ],
    );
  }
}

class PredefinedCollectionSection extends StatefulWidget {
  final List<PredefinedCollectionModel> listPredefinedCollection;
  final PredefinedCollectionType predefinedCollectionType;
  final String searchStr;

  const PredefinedCollectionSection(
      {super.key,
      required this.listPredefinedCollection,
      required this.predefinedCollectionType,
      required this.searchStr});

  @override
  State<PredefinedCollectionSection> createState() =>
      _PredefinedCollectionSectionState();
}

class _PredefinedCollectionSectionState
    extends State<PredefinedCollectionSection> {
  Widget _header(BuildContext context, int total) {
    final title =
        widget.predefinedCollectionType == PredefinedCollectionType.medium
            ? 'medium'.tr()
            : 'artists'.tr();
    final subTitle =
        widget.predefinedCollectionType == PredefinedCollectionType.medium
            ? ""
            : "$total";
    return SectionHeader(title: title, subTitle: subTitle);
  }

  Widget _icon(PredefinedCollectionModel predefinedCollection) {
    switch (widget.predefinedCollectionType) {
      case PredefinedCollectionType.medium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColor.auLightGrey,
          ),
          child: SvgPicture.asset(
            MediumCategoryExt.icon(predefinedCollection.id),
            width: 22,
            colorFilter:
                const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          ),
        );
      case PredefinedCollectionType.artist:
        final compactedAssetTokens = predefinedCollection.compactedAssetToken;
        return SizedBox(
          width: 42,
          height: 42,
          child: tokenGalleryThumbnailWidget(context, compactedAssetTokens, 100,
              usingThumbnailID: false,
              galleryThumbnailPlaceholder: Container(
                width: 42,
                height: 42,
                color: AppColor.auLightGrey,
              )),
        );
    }
  }

  Widget _item(
      BuildContext context, PredefinedCollectionModel predefinedCollection) {
    final theme = Theme.of(context);
    var title = predefinedCollection.name ?? predefinedCollection.id;
    if (predefinedCollection.name == predefinedCollection.id) {
      title = title.maskOnly(5);
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.predefinedCollectionPage,
          arguments: PredefinedCollectionScreenPayload(
            type: widget.predefinedCollectionType,
            predefinedCollection: predefinedCollection,
            filterStr: widget.searchStr,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _icon(
              predefinedCollection,
            ),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.ppMori400Black14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${predefinedCollection.total}',
                style: theme.textTheme.ppMori400Grey14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listPredefinedCollection = widget.listPredefinedCollection;
    const padding = 15.0;
    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, listPredefinedCollection.length),
          addDivider(color: AppColor.primaryBlack),
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                separatorBuilder: (BuildContext context, int index) {
                  return addDivider();
                },
                itemBuilder: (BuildContext context, int index) {
                  final predefinedCollection = listPredefinedCollection[index];
                  return _item(context, predefinedCollection);
                },
                itemCount: listPredefinedCollection.length,
              )
            ],
          ),
        ],
      ),
    );
  }
}

class WorksSection extends StatefulWidget {
  final List<CompactedAssetToken> works;

  const WorksSection({super.key, required this.works});

  @override
  State<WorksSection> createState() => _WorksSectionState();
}

class _WorksSectionState extends State<WorksSection> {
  @override
  void initState() {
    super.initState();
  }

  Widget _artworkItem(BuildContext context, CompactedAssetToken token) {
    final theme = Theme.of(context);
    final title = token.title ?? "";
    final artistName = token.artistTitle ?? token.artistID ?? "";
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.artworkDetailsPage,
          arguments: ArtworkDetailPayload(
            [
              ArtworkIdentity(token.id, token.owner),
            ],
            0,
          ),
        );
      },
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: GaleryThumbnailItem(
              assetToken: token,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.artworkDetailsPage,
                  arguments: ArtworkDetailPayload(
                    [
                      ArtworkIdentity(token.id, token.owner),
                    ],
                    0,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 19),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.ppMori400Black14,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artistName,
                  style: theme.textTheme.ppMori400Black14
                      .copyWith(color: AppColor.auLightGrey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const padding = 15.0;
    final compactedAssetTokens = widget.works;

    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        children: [
          SectionHeader(
              title: "works".tr(), subTitle: "${compactedAssetTokens.length}"),
          addDivider(color: AppColor.primaryBlack),
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                  itemBuilder: (BuildContext context, int index) {
                    final token = compactedAssetTokens[index];
                    return SizedBox(
                        height: 164, child: _artworkItem(context, token));
                  },
                  itemCount: compactedAssetTokens.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return addDivider(color: AppColor.auLightGrey);
                  }),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionInfo {
  Map<CollectionProSection, bool> state;

  SectionInfo({required this.state});
}

enum CollectionProSection {
  collection,
  medium,
  artist;

  static List<CollectionProSection> get allSections {
    return [
      CollectionProSection.collection,
      CollectionProSection.medium,
      CollectionProSection.artist,
    ];
  }
}
