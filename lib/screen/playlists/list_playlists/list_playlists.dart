import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';

class ListPlaylistsScreen extends StatefulWidget {
  final ValueNotifier<List<PlayListModel>?> playlists;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function() onAdd;
  final String filter;

  const ListPlaylistsScreen(
      {required this.playlists,
      required this.onReorder,
      required this.onAdd,
      super.key,
      this.filter = ''});

  @override
  State<ListPlaylistsScreen> createState() => _ListPlaylistsScreenState();
}

class _ListPlaylistsScreenState extends State<ListPlaylistsScreen>
    with RouteAware, WidgetsBindingObserver {
  final isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<PlayListModel>?>(
        valueListenable: widget.playlists,
        builder: (context, value, child) {
          if (value == null) {
            return const SizedBox.shrink();
          }
          List<PlayListModel> playlists = value.filter(widget.filter);
          if (playlists.isEmpty && widget.filter.isNotEmpty) {
            return const SizedBox();
          }
          const height = 165.0;
          return SizedBox(
            height: height,
            width: 400,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length + 1,
                itemBuilder: (context, index) {
                  if (index == playlists.length) {
                    if (widget.filter.isNotEmpty) {
                      return const SizedBox();
                    }
                    return AddPlayListItem(
                      onTap: () {
                        widget.onAdd();
                      },
                    );
                  }
                  final item = playlists[index];
                  return PlaylistItem(
                    playlist: item,
                    onSelected: () async {
                      Navigator.pushNamed(
                        context,
                        AppRouter.viewPlayListPage,
                        arguments:
                            ViewPlaylistScreenPayload(playListModel: item),
                      );
                      final tokenIds = item.tokenIDs;
                      if (tokenIds != null && tokenIds.isNotEmpty) {
                        final _bloc = injector.get<CanvasDeviceBloc>();
                        final controllingDevice = _bloc.state.controllingDevice;
                        if (controllingDevice != null) {
                          final duration = speedValues.values.first;
                          final List<PlayArtworkV2> castArtworks = tokenIds
                              .map((e) => PlayArtworkV2(
                                    token: CastAssetToken(id: e),
                                    duration: duration.inMilliseconds,
                                  ))
                              .toList();
                          _bloc.add(CanvasDeviceChangeControlDeviceEvent(
                              controllingDevice, castArtworks));
                        }
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 10),
              ),
            ),
          );
        },
      );
}

class PlaylistItem extends StatefulWidget {
  final Function()? onSelected;
  final PlayListModel playlist;
  final bool onHold;

  const PlaylistItem({
    required this.playlist,
    super.key,
    this.onSelected,
    this.onHold = false,
  });

  @override
  State<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormatter = NumberFormat('#,###');
    final thumbnailURL = widget.playlist.thumbnailURL;
    final name = widget.playlist.getName();
    const width = 140.0;
    const height = 165.0;
    return GestureDetector(
      onTap: widget.onSelected,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColor.white,
            border: Border.all(
              color: widget.onHold
                  ? AppColor.feralFileHighlight
                  : Colors.transparent,
              width: widget.onHold ? 2 : 0,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.ppMori400Black14,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    numberFormatter
                        .format(widget.playlist.tokenIDs?.length ?? 0),
                    style: theme.textTheme.ppMori400Grey14,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Center(
                  child: thumbnailURL == null || thumbnailURL.isEmpty
                      ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: theme.disableColor,
                        )
                      : CachedNetworkImage(
                          imageUrl: thumbnailURL,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: theme.disableColor,
                          ),
                          fadeInDuration: Duration.zero,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPlayListItem extends StatelessWidget {
  final Function()? onTap;

  const AddPlayListItem({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 165,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: theme.auLightGrey,
            ),
            color: AppColor.white),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'new_playlist'.tr(),
                    style: theme.textTheme.ppMori400Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Expanded(
              child: Center(
                child: Icon(
                  AuIcon.add,
                  color: AppColor.primaryBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
