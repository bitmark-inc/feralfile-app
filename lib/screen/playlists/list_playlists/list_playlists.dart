import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/horizontal_grid_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

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

  List<PlayListModel> _mapperPlaylist(List<PlayListModel> list) {
    List<PlayListModel> newList = [];

    if (list.length <= 3) return list;
    newList = list;
    if (newList.length < 6) {
      final fakePlaylistList = List.generate(
          6 - newList.length,
          (index) => FakePlaylistModel(
                name: "",
                thumbnailURL: "",
                tokenIDs: [],
              ));
      newList.addAll(fakePlaylistList);
    }
    return newList;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: widget.playlists,
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox.shrink();
        }
        List<PlayListModel> playlists = _mapperPlaylist(value);
        final cellPerColumn = playlists.length > 3 ? 2 : 1;
        const cellSpacing = 15.0;
        final height = cellPerColumn * 165 + (cellPerColumn - 1) * cellSpacing;
        return SizedBox(
          height: height,
          width: 400,
          child: HorizontalReorderableGridview<PlayListModel>(
              items: playlists,
              onReorder: widget.onReorder,
              cellPerColumn: cellPerColumn,
              cellSpacing: cellSpacing,
              childAspectRatio: 165 / 140,
              onDragStart: (index) {
                Vibrate.feedback(FeedbackType.light);
              },
              itemCount: playlists.length,
              itemBuilder: (item) {
                if (item is FakePlaylistModel) {
                  return Container(
                    width: 140,
                    height: 165,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }
                return PlaylistItem(
                  playlist: item,
                  onSelected: () => Navigator.pushNamed(
                    context,
                    AppRouter.viewPlayListPage,
                    arguments: ViewPlaylistScreenPayload(playListModel: item),
                  ),
                );
              }),
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
                  Text(
                    (name?.isNotEmpty ?? false) ? name! : 'Untitled',
                    style: theme.textTheme.ppMori400White14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
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

class FakePlaylistModel extends PlayListModel {
  FakePlaylistModel({
    String? name,
    String? thumbnailURL,
    List<String>? tokenIDs,
  }) : super(
          name: name,
          thumbnailURL: thumbnailURL,
          tokenIDs: tokenIDs,
        );
}
