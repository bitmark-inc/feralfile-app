import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/device_setting/now_displaying_page.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

class ExhibitionDisplaying {
  final Exhibition? exhibition;
  final String? catalogId;
  final ExhibitionCatalog? catalog;
  final Artwork? artwork;

  ExhibitionDisplaying({
    this.exhibition,
    this.catalogId,
    this.catalog,
    this.artwork,
  });
}

class NowDisplayingObject {
  final AssetToken? assetToken;
  final ExhibitionDisplaying? exhibitionDisplaying;

  NowDisplayingObject({
    this.assetToken,
    this.exhibitionDisplaying,
  });
}

class NowDisplayingManager {
  factory NowDisplayingManager() => _instance;

  static Timer? _timer;

  NowDisplayingManager._internal();

  static final NowDisplayingManager _instance =
      NowDisplayingManager._internal();

  NowDisplayingObject? nowDisplaying;
  final StreamController<NowDisplayingObject?> _streamController =
      StreamController.broadcast();

  Stream<NowDisplayingObject?> get nowDisplayingStream =>
      _streamController.stream;

  Future<void> updateDisplayingNow() async {
    final status = _getStatus();
    final nowDisplaying = await getNowDisplayingObject();
    this.nowDisplaying = nowDisplaying;
    _streamController.add(nowDisplaying);
    if (nowDisplaying?.assetToken != null) {
      _timer?.cancel();
      final duration = (status?.remainDurationCurrentArtwork ??
              const Duration(seconds: 27)) +
          const Duration(seconds: 3);
      log.info('Update token in $duration');
      _timer = Timer(duration, () {
        final castingDevice =
            injector<FFBluetoothService>().castingBluetoothDevice;
        if (castingDevice == null) return;
        injector<CanvasDeviceBloc>()
            .add(CanvasDeviceGetStatusEvent(castingDevice));
        // updateDisplayingNow();
      });
    } else {
      _timer?.cancel();
    }
  }

  Future<NowDisplayingObject?> getNowDisplayingObject() async {
    final status = _getStatus();
    if (status == null) {
      return null;
    }
    if (status.exhibitionId != null) {
      final exhibitionId = status.exhibitionId!;
      final exhibition = await injector<FeralFileService>().getExhibition(
        exhibitionId,
      );
      final catalogId = status.catalogId;
      final catalog = catalogId != null ? ExhibitionCatalog.artwork : null;
      Artwork? artwork;
      if (catalog == ExhibitionCatalog.artwork) {
        artwork = await injector<FeralFileService>().getArtwork(
          catalogId!,
        );
      }
      final exhibitionDisplaying = ExhibitionDisplaying(
        exhibition: exhibition,
        catalogId: catalogId,
        catalog: catalog,
        artwork: artwork,
      );
      return NowDisplayingObject(exhibitionDisplaying: exhibitionDisplaying);
    } else {
      final index = status.currentArtworkIndex;
      if (index == null) {
        return null;
      }
      final tokenId = status.artworks[index].token?.id;
      if (tokenId == null) {
        return null;
      }
      final assetToken = await _fetchAssetToken(tokenId);
      return NowDisplayingObject(assetToken: assetToken);
    }
  }

  Future<AssetToken?> _fetchAssetToken(String tokenId) async {
    final request = QueryListTokensRequest(ids: [tokenId]);
    final assetToken = await injector<IndexerService>().getNftTokens(request);
    return assetToken.isNotEmpty ? assetToken.first : null;
  }

  CheckDeviceStatusReply? _getStatus() {
    final castingDevice = injector<FFBluetoothService>().castingBluetoothDevice;
    if (castingDevice == null) return null;

    final canvasState = injector<CanvasDeviceBloc>().state;
    final status = canvasState.canvasDeviceStatus[castingDevice.remoteID];
    return status;
  }
}

class NowDisplaying extends StatefulWidget {
  const NowDisplaying({super.key});

  @override
  State<NowDisplaying> createState() => _NowDisplayingState();
}

class _NowDisplayingState extends State<NowDisplaying> {
  final NowDisplayingManager _manager = NowDisplayingManager();
  NowDisplayingObject? nowDisplaying;

  @override
  void initState() {
    super.initState();
    nowDisplaying = _manager.nowDisplaying;
    _manager.nowDisplayingStream.listen(
      (nowDisplayingObject) {
        if (mounted) {
          setState(
            () {
              nowDisplaying = nowDisplayingObject;
            },
          );
        }
      },
    );
    _manager.updateDisplayingNow();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      listener: (context, state) {
        _manager.updateDisplayingNow();
      },
      builder: (context, state) {
        final nowDisplaying = this.nowDisplaying;
        if (nowDisplaying == null) {
          return const SizedBox();
        }
        final assetToken = nowDisplaying.assetToken;
        if (assetToken != null) {
          return _tokenNowDisplayingView(context, assetToken);
        }
        final exhibitionDisplaying = nowDisplaying.exhibitionDisplaying;
        if (exhibitionDisplaying != null) {
          return _exhibitionNowDisplayingView(context, exhibitionDisplaying);
        }
        return const SizedBox();
      },
    );
  }
}

Widget _tokenNowDisplayingView(BuildContext context, AssetToken assetToken) {
  return GestureDetector(
    child: TokenNowDisplayingView(
      CompactedAssetToken.fromAssetToken(assetToken),
    ),
    onTap: () {
      final payload = NowDisplayingPagePayload(
        artworkIdentity: ArtworkIdentity(assetToken.id, assetToken.owner),
      );
      const pageName = AppRouter.nowDisplayingPage;
      Navigator.of(context).pushNamed(pageName, arguments: payload);
    },
  );
}

Widget _exhibitionNowDisplayingView(
    BuildContext context, ExhibitionDisplaying exhibitionDisplaying) {
  return GestureDetector(
    child: NowDisplayingExhibitionView(exhibitionDisplaying),
    onTap: () {
      final exhibition = exhibitionDisplaying.exhibition;
      final artwork = exhibitionDisplaying.artwork;
      if (artwork != null) {
        injector<NavigationService>().navigateTo(
          AppRouter.ffArtworkPreviewPage,
          arguments: FeralFileArtworkPreviewPagePayload(
            artwork: artwork,
          ),
        );
      } else if (exhibition != null) {
        injector<NavigationService>().navigateTo(
          AppRouter.exhibitionDetailPage,
          arguments: ExhibitionDetailPayload(
            exhibitions: [exhibition],
            index: 0,
          ),
        );
      }
    },
  );
}

class TokenNowDisplayingView extends StatelessWidget {
  const TokenNowDisplayingView(this.assetToken, {super.key});

  final CompactedAssetToken assetToken;

  IdentityBloc get _identityBloc => injector<IdentityBloc>();

  @override
  Widget build(BuildContext context) {
    _identityBloc.add(GetIdentityEvent([assetToken.artistTitle ?? '']));
    final theme = Theme.of(context);
    return BlocBuilder<IdentityBloc, IdentityState>(
      bloc: _identityBloc,
      builder: (context, state) {
        final artistTitle =
            assetToken.artistTitle?.toIdentityOrMask(state.identityMap) ??
                assetToken.artistTitle;
        return NowDisplayingView(thumbnailBuilder: (context) {
          return tokenGalleryThumbnailWidget(
            context,
            assetToken,
            65,
            useHero: false,
          );
        }, titleBuilder: (context) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (artistTitle != null) ...[
                GestureDetector(
                  onTap: () {
                    if (assetToken.isFeralfile) {
                      injector<NavigationService>().openFeralFileArtistPage(
                        assetToken.artistID!,
                      );
                    } else {
                      final uri = Uri.parse(
                        assetToken.artistURL?.split(' & ').firstOrNull ?? '',
                      );
                      injector<NavigationService>().openUrl(uri);
                    }
                  },
                  child: Text(
                    artistTitle,
                    style: theme.textTheme.ppMori400Black14.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColor.primaryBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
              ],
              if (assetToken.title != null)
                Expanded(
                  child: Text(
                    assetToken.title!,
                    style: theme.textTheme.ppMori400Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}

class NowDisplayingExhibitionView extends StatelessWidget {
  const NowDisplayingExhibitionView(this.exhibitionDisplaying, {super.key});

  final ExhibitionDisplaying exhibitionDisplaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exhibition = exhibitionDisplaying.exhibition;
    final artwork = exhibitionDisplaying.artwork;
    final thumbnailUrl = artwork?.smallThumbnailURL ?? exhibition?.coverUrl;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return FFCacheNetworkImage(imageUrl: thumbnailUrl ?? '');
      },
      titleBuilder: (context) {
        if (artwork != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  injector<NavigationService>().openFeralFileArtistPage(
                    artwork.series?.artistAlumniAccountID ?? '',
                  );
                },
                child: Text(
                  artwork.series?.artistAlumni?.alias ?? '',
                  style: theme.textTheme.ppMori400Black14.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColor.primaryBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  artwork.series?.title ?? '',
                  style: theme.textTheme.ppMori400Black14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return Text(
          exhibition?.title ?? '',
          style: theme.textTheme.ppMori400Black14,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class NowDisplayingView extends StatelessWidget {
  const NowDisplayingView(
      {super.key, required this.thumbnailBuilder, required this.titleBuilder});

  final Widget Function(BuildContext) thumbnailBuilder;
  final Widget Function(BuildContext) titleBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.feralFileLightBlue,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 65,
            child: thumbnailBuilder(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Now Displaying:',
                  style: theme.textTheme.ppMori400Black14,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                titleBuilder(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
