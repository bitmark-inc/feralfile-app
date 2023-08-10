import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class ListPlaylistsScreen extends StatefulWidget {
  const ListPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<ListPlaylistsScreen> createState() => _ListPlaylistsScreenState();
}

class _ListPlaylistsScreenState extends State<ListPlaylistsScreen>
    with RouteAware, WidgetsBindingObserver {
  final ValueNotifier<List<PlayListModel>?> _playlists = ValueNotifier(null);
  final isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();

  Future<List<PlayListModel>?> getPlaylist() async {
    final playlistService = injector.get<PlaylistService>();
    final isSubscribed = await injector.get<IAPService>().isSubscribed();
    if (!isSubscribed && !isDemo) return null;
    if (isDemo) {
      return injector<VersionService>().getDemoAccountFromGithub();
    }
    return playlistService.getPlayList();
  }

  _initPlayList() async {
    _playlists.value = await getPlaylist();
  }

  @override
  void initState() {
    super.initState();
    _initPlayList();
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

  _onUpdatePlaylists() async {
    if (isDemo || _playlists.value == null) return;
    await injector
        .get<PlaylistService>()
        .setPlayList(_playlists.value!, override: true);
    injector.get<SettingsDataService>().backup();
  }

  @override
  void didPopNext() {
    _initPlayList();
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: _playlists,
      builder: (context, value, child) => value == null
          ? const SizedBox.shrink()
          : ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            onReorderStart: (index) {
              Vibrate.feedback(FeedbackType.light);
            },
            proxyDecorator: (child, index, animation) {
              return PlaylistItem(
                key: ValueKey(value[index]),
                playlist: value[index],
                onHold: true,
              );
            },
            itemCount: value.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = value.removeAt(oldIndex);
                value.insert(newIndex, item);
                _onUpdatePlaylists();
              });
            },
            itemBuilder: (context, index) {
              return PlaylistItem(
              key: ValueKey(value[index]),
              playlist: value[index],
              onSelected: () => Navigator.pushNamed(
                context,
                AppRouter.viewPlayListPage,
                arguments: value[index],
              ).then((value) {
                _initPlayList();
              }),
            );},
          ),
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
        padding: const EdgeInsets.only(right: 15),
        child: Container(
          width: height,
          height: width,
          decoration: BoxDecoration(
            color: Colors.amber,
            border: Border.all(
              color: widget.onHold
                  ? theme.auSuperTeal
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
                  Text(
                    (name?.isNotEmpty ?? false) ? name! : 'Untitled',
                    style: theme.textTheme.ppMori400Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    numberFormater.format(widget.playlist.tokenIDs?.length ?? 0),
                    style: theme.textTheme.ppMori400Grey14,),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(child:
                  Center(child:
              thumbnailURL == null ||
                      thumbnailURL.isEmpty
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
                    ),),),

            ],
          ),
        ),
      ),
    );
  }
}
