import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ListPlaylistsScreen extends StatefulWidget {
  final ValueNotifier<List<PlayListModel>?> playlists;
  final Function(int oldIndex, int newIndex) onReorder;
  final String filter;

  const ListPlaylistsScreen(
      {Key? key,
      required this.playlists,
      required this.onReorder,
      this.filter = ""})
      : super(key: key);

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
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: widget.playlists,
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox.shrink();
        }
        List<PlayListModel> playlists = value.filter(widget.filter);
        if (playlists.isEmpty) return const SizedBox();
        const height = 165.0;
        return SizedBox(
          height: height,
          width: 400,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final item = playlists[index];
                return PlaylistItem(
                  playlist: item,
                  onSelected: () => Navigator.pushNamed(
                    context,
                    AppRouter.viewPlayListPage,
                    arguments: ViewPlaylistScreenPayload(playListModel: item),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const SizedBox(width: 10);
              },
            ),
          ),
        );
      },
    );
  }
}

class PlaylistItem extends StatefulWidget {
  final Function()? onSelected;
  final PlayListModel playlist;
  final bool onHold;

  const PlaylistItem({
    Key? key,
    this.onSelected,
    required this.playlist,
    this.onHold = false,
  }) : super(key: key);

  @override
  State<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormater = NumberFormat("#,###");
    final thumbnailURL = widget.playlist.thumbnailURL;
    final name = widget.playlist.name;
    const width = 140.0;
    const height = 165.0;
    return GestureDetector(
      onTap: widget.onSelected,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          width: height,
          height: width,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: widget.onHold ? theme.auSuperTeal : Colors.transparent,
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
                      (name?.isNotEmpty ?? false) ? name! : 'Untitled',
                      style: theme.textTheme.ppMori400White14,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    numberFormater
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
                          errorWidget: (context, url, error) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: theme.disableColor,
                            );
                          },
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
