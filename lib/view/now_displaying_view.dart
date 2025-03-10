import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class NowDisplayingStatus {}

class ConnectingToDevice implements NowDisplayingStatus {
  ConnectingToDevice(this.device);

  final BluetoothDevice device;
}

class NowDisplayingSuccess implements NowDisplayingStatus {
  NowDisplayingSuccess(this.object);

  final NowDisplayingObject object;
}

class NowDisplayingError implements NowDisplayingStatus {
  NowDisplayingError(this.error);

  final Object error;
}

class ConnectSuccess implements NowDisplayingStatus {
  ConnectSuccess(this.device);

  final BluetoothDevice device;
}

// connect failed
class ConnectFailed implements NowDisplayingStatus {
  ConnectFailed(this.device, this.error);

  final BluetoothDevice device;
  final Object error;
}

class ConnectionLostAndReconnecting implements NowDisplayingStatus {
  ConnectionLostAndReconnecting(this.device);

  final BluetoothDevice device;
}

class GettingNowDisplayingObject implements NowDisplayingStatus {}

class ExhibitionDisplaying {
  ExhibitionDisplaying({
    this.exhibition,
    this.catalogId,
    this.catalog,
    this.artwork,
  });

  final Exhibition? exhibition;
  final String? catalogId;
  final ExhibitionCatalog? catalog;
  final Artwork? artwork;
}

class NowDisplayingObject {
  NowDisplayingObject({
    this.assetToken,
    this.exhibitionDisplaying,
    this.dailiesWorkState,
  });

  final AssetToken? assetToken;
  final ExhibitionDisplaying? exhibitionDisplaying;
  final DailiesWorkState? dailiesWorkState;
}

class NowDisplaying extends StatefulWidget {
  const NowDisplaying({super.key});

  @override
  State<NowDisplaying> createState() => _NowDisplayingState();
}

class _NowDisplayingState extends State<NowDisplaying> {
  final NowDisplayingManager _manager = NowDisplayingManager();
  NowDisplayingStatus? nowDisplayingStatus;

  @override
  void initState() {
    super.initState();
    nowDisplayingStatus = _manager.nowDisplayingStatus;
    _manager.nowDisplayingStream.listen(
      (status) {
        if (mounted) {
          setState(
            () {
              nowDisplayingStatus = status;
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      listener: (context, state) {},
      builder: (context, state) {
        final nowDisplayingStatus = this.nowDisplayingStatus;
        if (nowDisplayingStatus == null) {
          return const SizedBox();
        }
        switch (nowDisplayingStatus.runtimeType) {
          case ConnectingToDevice:
            return _connectingToDeviceView(context, nowDisplayingStatus);
          case ConnectSuccess:
            return _connectSuccessView(context, nowDisplayingStatus);
          case ConnectFailed:
            return _connectFailedView(context, nowDisplayingStatus);
          case ConnectionLostAndReconnecting:
            return _connectionLostAndReconnectingView(
                context, nowDisplayingStatus);
          case GettingNowDisplayingObject:
            return _gettingNowDisplayingObjectView(context);
          case NowDisplayingSuccess:
            return NowDisplayingSuccessWidget(
              object: (nowDisplayingStatus as NowDisplayingSuccess).object,
            );
          case NowDisplayingError:
            return _getNowDisplayingErrorView(context, nowDisplayingStatus);
          default:
            return const SizedBox();
        }
      },
    );
  }

  Widget _connectingToDeviceView(
      BuildContext context, NowDisplayingStatus status) {
    final device = (status as ConnectingToDevice).device;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Connecting to ${device.advName}...',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }

  Widget _connectSuccessView(BuildContext context, NowDisplayingStatus status) {
    final device = (status as ConnectSuccess).device;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Connected to ${device.advName}',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }

  Widget _connectFailedView(BuildContext context, NowDisplayingStatus status) {
    final device = (status as ConnectFailed).device;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Failed to connect to ${device.advName}',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }

  Widget _connectionLostAndReconnectingView(
      BuildContext context, NowDisplayingStatus status) {
    final device = (status as ConnectionLostAndReconnecting).device;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Connection lost. Reconnecting to ${device.advName}...',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }

  Widget _gettingNowDisplayingObjectView(BuildContext context) {
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Getting now displaying object...',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }

  Widget _getNowDisplayingErrorView(
      BuildContext context, NowDisplayingStatus nowDisplayingStatus) {
    final error = (nowDisplayingStatus as NowDisplayingError).error;
    return NowDisplayingView(
      thumbnailBuilder: (context) {
        return SizedBox(
          width: 65,
        );
      },
      titleBuilder: (context) {
        return Text(
          'Error: $error',
          style: Theme.of(context).textTheme.ppMori400Black14,
        );
      },
    );
  }
}

class NowDisplayingSuccessWidget extends StatefulWidget {
  const NowDisplayingSuccessWidget({super.key, required this.object});

  final NowDisplayingObject object;

  @override
  State<NowDisplayingSuccessWidget> createState() =>
      _NowDisplayingSuccessWidgetState();
}

class _NowDisplayingSuccessWidgetState
    extends State<NowDisplayingSuccessWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nowDisplaying = widget.object;
    final assetToken = nowDisplaying.assetToken;
    if (assetToken != null) {
      return _tokenNowDisplayingView(context, assetToken);
    }
    final exhibitionDisplaying = nowDisplaying.exhibitionDisplaying;
    if (exhibitionDisplaying != null) {
      return _exhibitionNowDisplayingView(context, exhibitionDisplaying);
    }
    if (nowDisplaying.dailiesWorkState != null) {
      return _dailyWorkNowDisplayingView(
          context, nowDisplaying.dailiesWorkState!);
    }
    return const SizedBox();
  }
}

Widget _tokenNowDisplayingView(BuildContext context, AssetToken assetToken) {
  return GestureDetector(
    child: TokenNowDisplayingView(
      CompactedAssetToken.fromAssetToken(assetToken),
    ),
    onTap: () {
      const pageName = AppRouter.nowDisplayingPage;
      injector<NavigationService>().navigateTo(
        pageName,
      );
    },
  );
}

Widget _dailyWorkNowDisplayingView(
    BuildContext context, DailiesWorkState state) {
  final assetToken = state.assetTokens.firstOrNull;
  if (assetToken == null) {
    return const SizedBox();
  }
  return GestureDetector(
    child: TokenNowDisplayingView(
      CompactedAssetToken.fromAssetToken(assetToken),
    ),
    onTap: () {
      injector<NavigationService>().navigateTo(
        AppRouter.nowDisplayingPage,
      );
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
          AppRouter.nowDisplayingPage,
        );
      } else if (exhibition != null) {
        injector<NavigationService>().navigateTo(
          AppRouter.nowDisplayingPage,
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
        return NowDisplayingView(
          thumbnailBuilder: (context) {
            return AspectRatio(
              aspectRatio: 1,
              child: tokenGalleryThumbnailWidget(
                context,
                assetToken,
                65,
                useHero: false,
              ),
            );
          },
          titleBuilder: (context) {
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
                      assetToken.displayTitle!,
                      style: theme.textTheme.ppMori400Black14,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            );
          },
        );
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
        return AspectRatio(
          child: FFCacheNetworkImage(imageUrl: thumbnailUrl ?? ''),
          aspectRatio: 1,
        );
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
      constraints: const BoxConstraints(maxHeight: 100, minHeight: 100),
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
