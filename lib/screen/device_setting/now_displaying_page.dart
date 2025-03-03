import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/keyboard_control_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class NowDisplayingPagePayload {
  NowDisplayingPagePayload({required this.artworkIdentity});

  final ArtworkIdentity artworkIdentity;
}

class NowDisplayingPage extends StatefulWidget {
  const NowDisplayingPage({required this.payload, super.key});

  final NowDisplayingPagePayload payload;

  @override
  State<NowDisplayingPage> createState() => NowDisplayingPageState();
}

class NowDisplayingPageState extends State<NowDisplayingPage> {
  final NowDisplayingManager _manager = NowDisplayingManager();
  NowDisplayingObject? nowDisplaying;

  @override
  void initState() {
    super.initState();
    nowDisplaying = _manager.nowDisplaying;
    _onUpdateNowDisplaying(nowDisplaying!);

    _manager.nowDisplayingStream.listen(
      (nowDisplayingObject) {
        if (mounted) {
          setState(
            () {
              nowDisplaying = nowDisplayingObject;
            },
          );
          _onUpdateNowDisplaying(nowDisplayingObject);
        }
      },
    );
  }

  void _onUpdateNowDisplaying(NowDisplayingObject? nowDisplayingObject) {
    final assetToken = nowDisplayingObject?.assetToken ??
        nowDisplayingObject?.dailiesWorkState?.assetTokens.firstOrNull;
    if (assetToken != null) {
      final artworkIdentity = ArtworkIdentity(
        assetToken.id,
        assetToken.owner,
      );
      context.read<ArtworkDetailBloc>().add(ArtworkDetailGetInfoEvent(
          artworkIdentity,
          withArtwork: true,
          useIndexer: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canvasState = injector<CanvasDeviceBloc>().state;
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: 'now_displaying'.tr(),
        isWhite: false,
      ),
      backgroundColor: AppColor.primaryBlack,
      body: BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
        listener: (context, state) {
          final identitiesList = state.provenances.map((e) => e.owner).toList();
          if (state.assetToken?.artistName != null &&
              state.assetToken!.artistName!.length > 20) {
            identitiesList.add(state.assetToken!.artistName!);
          }

          identitiesList.add(state.assetToken?.owner ?? '');
          context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
        },
        builder: (context, state) {
          final assetToken = state.assetToken;
          if (assetToken == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final identityState = context.watch<IdentityBloc>().state;
          final asset = state.assetToken!;
          final artistName =
              asset.artistName?.toIdentityOrMask(identityState.identityMap);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 30,
                ),
              ),
              SliverToBoxAdapter(
                child: _artworkPreview(context, assetToken),
              ),
              SliverToBoxAdapter(
                child: infoHeader(context, asset, artistName, canvasState),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HtmlWidget(
                    customStylesBuilder: auHtmlStyle,
                    assetToken.description ?? '',
                    textStyle: theme.textTheme.ppMori400White14,
                    onTapUrl: (url) async {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                      return true;
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              if (state.exhibition != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: exhibitionInfo(
                      context,
                      state.artwork!.series!.exhibition!,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: artworkDetailsMetadataSection(
                    context,
                    assetToken,
                    artistName,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: artworkDetailsRightSection(
                    context,
                    assetToken,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: SizedBox(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _artworkPreview(BuildContext context, AssetToken assetToken) {
    final state = injector<CanvasDeviceBloc>().state;
    final castingDevice = state.devices
        .firstWhereOrNull((device) =>
            state.canvasDeviceStatus[device.device.deviceId]?.artworks
                .where((artwork) => artwork.token?.id == assetToken.id)
                .isNotEmpty ??
            false)
        ?.device;
    // injector<CanvasDeviceBloc>()
    //     .state
    //     .lastSelectedActiveDeviceForKey(assetToken.displayKey);
    final screenWidth = MediaQuery.of(context).size.width;
    return ColoredBox(
      color: AppColor.auGreyBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: tokenGalleryThumbnailWidget(
              context,
              CompactedAssetToken.fromAssetToken(assetToken),
              screenWidth.toInt(),
            ),
          ),
          const Divider(
            color: AppColor.primaryBlack,
            height: 1,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              onTap: () {
                injector<NavigationService>().navigateTo(
                  AppRouter.keyboardControlPage,
                  arguments: KeyboardControlPagePayload(
                    getEditionSubTitle(assetToken),
                    assetToken.description ?? '',
                    [if (castingDevice != null) castingDevice],
                  ),
                );
              },
              color: AppColor.white,
              text: 'interact'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget infoHeader(
  BuildContext context,
  AssetToken asset,
  String? artistName,
  CanvasDeviceState canvasState,
) {
  var subTitle = '';
  if (artistName != null && artistName.isNotEmpty) {
    subTitle = artistName;
  }
  return Padding(
    padding: const EdgeInsets.fromLTRB(15, 15, 5, 20),
    child: Row(
      children: [
        Expanded(
          child: ArtworkDetailsHeader(
            title: asset.displayTitle ?? '',
            subTitle: subTitle,
            onSubTitleTap: asset.artistID != null && asset.isFeralfile
                ? () => unawaited(
                      injector<NavigationService>()
                          .openFeralFileArtistPage(asset.artistID!),
                    )
                : null,
          ),
        ),
      ],
    ),
  );
}
