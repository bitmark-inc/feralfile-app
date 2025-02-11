import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/device_setting/now_displaying_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

class NowDisplayingManager {
  factory NowDisplayingManager() => _instance;

  static Timer? _timer;

  NowDisplayingManager._internal();

  static final NowDisplayingManager _instance =
      NowDisplayingManager._internal();

  AssetToken? assetToken;
  final StreamController<AssetToken?> _streamController =
      StreamController.broadcast();

  Stream<AssetToken?> get assetTokenStream => _streamController.stream;

  Future<void> updateToken() async {
    final tokenId = _getCurrentDisplayingTokenId();
    if (tokenId == null) {
      _streamController.add(null);
      _timer?.cancel();
      return;
    } else {
      _timer?.cancel();
      final duration =
          (_remainDurationCurrentArtwork() ?? const Duration(seconds: 27)) +
              const Duration(seconds: 3);
      log.info('Update token in $duration');
      _timer = Timer(duration, () {
        updateToken();
      });
    }
    if (this.assetToken?.id == tokenId) return;
    final assetToken = await _fetchAssetToken(tokenId);
    if (assetToken != null) {
      this.assetToken = assetToken;
      _streamController.add(assetToken);
    }
  }

  Future<AssetToken?> _fetchAssetToken(String tokenId) async {
    final request = QueryListTokensRequest(ids: [tokenId]);
    final assetToken = await injector<IndexerService>().getNftTokens(request);
    return assetToken.isNotEmpty ? assetToken.first : null;
  }

  String? _getCurrentDisplayingTokenId() {
    final castingDevice = injector<FFBluetoothService>().castingBluetoothDevice;
    if (castingDevice == null) return null;

    final canvasState = injector<CanvasDeviceBloc>().state;
    final status = canvasState.canvasDeviceStatus[castingDevice.remoteID];
    if (status == null) return null;

    final currentIndex = status.currentArtworkIndex;
    if (currentIndex == null) return null;

    return status.artworks[currentIndex].token?.id;
  }

  Duration? _remainDurationCurrentArtwork() {
    final castingDevice = injector<FFBluetoothService>().castingBluetoothDevice;
    if (castingDevice == null) return null;

    final canvasState = injector<CanvasDeviceBloc>().state;
    final status = canvasState.canvasDeviceStatus[castingDevice.remoteID];
    if (status == null) return null;
    return status.remainDurationCurrentArtwork;
  }
}

class NowDisplaying extends StatefulWidget {
  const NowDisplaying({super.key});

  @override
  State<NowDisplaying> createState() => _NowDisplayingState();
}

class _NowDisplayingState extends State<NowDisplaying> {
  final NowDisplayingManager _manager = NowDisplayingManager();
  AssetToken? assetToken;

  @override
  void initState() {
    super.initState();
    assetToken = _manager.assetToken;
    _manager.assetTokenStream.listen(
      (token) {
        if (mounted) {
          setState(
            () {
              assetToken = token;
            },
          );
        }
      },
    );
    _manager.updateToken();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      listener: (context, state) {
        _manager.updateToken();
      },
      builder: (context, state) {
        if (assetToken == null) {
          return const SizedBox();
        }
        return GestureDetector(
          onTap: () {
            final payload = NowDisplayingPagePayload(
              artworkIdentity:
                  ArtworkIdentity(assetToken!.id, assetToken!.owner),
            );
            const pageName = AppRouter.nowDisplayingPage;
            Navigator.of(context).pushNamed(pageName, arguments: payload);
          },
          child: NowDisplayingView(
            CompactedAssetToken.fromAssetToken(assetToken!),
          ),
        );
      },
    );
  }
}

// class NowDisplaying extends StatefulWidget {
//   const NowDisplaying({super.key = const Key('NowDisplaying')});
//
//   @override
//   State<NowDisplaying> createState() => NowDisplayingState();
// }
//
// class NowDisplayingState extends State<NowDisplaying> {
//   static final NowDisplayingState _instance = NowDisplayingState._internal();
//
//   factory NowDisplayingState() => _instance;
//
//   NowDisplayingState._internal();
//
//   AssetToken? assetToken;
//
//   @override
//   void initState() {
//     super.initState();
//     final tokenId = _getCurrentDisplayingTokenId();
//     if (tokenId != null) {
//       _fetchAssetToken(tokenId);
//     }
//   }
//
//   Future<void> _fetchAssetToken(String tokenId) async {
//     final assetToken = await _getAssetToken(tokenId);
//     if (assetToken != null) {
//       setState(() {
//         this.assetToken = assetToken;
//       });
//     }
//   }
//
//   Future<AssetToken?> _getAssetToken(String tokenId) async {
//     final request = QueryListTokensRequest(
//       ids: [tokenId],
//     );
//     final assetToken = await injector<IndexerService>().getNftTokens(request);
//     return assetToken.isNotEmpty ? assetToken.first : null;
//   }
//
//   String? _getCurrentDisplayingTokenId() {
//     final castingDevice = injector<FFBluetoothService>().castingBluetoothDevice;
//     if (castingDevice == null) {
//       return null;
//     }
//     final canvasState = injector<CanvasDeviceBloc>().state;
//     final status = canvasState.canvasDeviceStatus[castingDevice.remoteID];
//     if (status == null) {
//       return null;
//     }
//     final currentIndex = status.currentArtworkIndex;
//     if (currentIndex == null) {
//       return null;
//     }
//     final artwork = status.artworks[currentIndex];
//     final tokenId = artwork.token?.id;
//     return tokenId;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
//       bloc: injector<CanvasDeviceBloc>(),
//       listener: (context, state) {
//         final tokenId = _getCurrentDisplayingTokenId();
//         if (tokenId != null && tokenId != assetToken?.id) {
//           _fetchAssetToken(tokenId);
//         }
//       },
//       builder: (context, state) {
//         if (assetToken == null) {
//           return const SizedBox();
//         }
//         return NowDisplayingView(
//             CompactedAssetToken.fromAssetToken(assetToken!));
//       },
//     );
//   }
// }

class NowDisplayingView extends StatelessWidget {
  const NowDisplayingView(this.assetToken, {super.key});

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
                child: tokenGalleryThumbnailWidget(
                  context,
                  assetToken,
                  65,
                  useHero: false,
                ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (artistTitle != null) ...[
                          GestureDetector(
                            onTap: () {
                              if (assetToken.isFeralfile) {
                                injector<NavigationService>()
                                    .openFeralFileArtistPage(
                                  assetToken.artistID!,
                                );
                              } else {
                                final uri = Uri.parse(
                                  assetToken.artistURL
                                          ?.split(' & ')
                                          .firstOrNull ??
                                      '',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
