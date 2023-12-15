import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
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

  _gotoCreatePlaylist() {
    Navigator.of(context).pushNamed(AppRouter.createPlayListPage).then((value) {
      if (value != null && value is PlayListModel) {
        Navigator.pushNamed(
          context,
          AppRouter.viewPlayListPage,
          arguments: value,
        );
      }
    });
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
          : SizedBox(
              height: 110,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                onReorderStart: (index) {
                  Vibrate.feedback(FeedbackType.light);
                },
                proxyDecorator: (child, index, animation) {
                  return PlaylistItem(
                    key: ValueKey(value[index]),
                    name: value[index].name,
                    thumbnailURL: value[index].thumbnailURL,
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
                footer: isDemo
                    ? null
                    : SizedBox(
                        height: 80,
                        width: 80,
                        child: AddPlayListItem(
                          onTap: _gotoCreatePlaylist,
                        ),
                      ),
                itemBuilder: (context, index) => PlaylistItem(
                  key: ValueKey(value[index]),
                  name: value[index].name,
                  thumbnailURL: value[index].thumbnailURL,
                  onSelected: () => Navigator.pushNamed(
                    context,
                    AppRouter.viewPlayListPage,
                    arguments: value[index],
                  ).then((value) {
                    _initPlayList();
                  }),
                ),
              ),
            ),
    );
  }
}

class PlaylistItem extends StatefulWidget {
  final Function()? onSelected;
  final String? name;
  final String? thumbnailURL;
  final bool onHold;

  const PlaylistItem({
    Key? key,
    this.onSelected,
    this.name,
    this.thumbnailURL,
    this.onHold = false,
  }) : super(key: key);

  @override
  State<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onSelected,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Container(
          width: 83,
          color: theme.colorScheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.onHold
                          ? theme.auSuperTeal
                          : Colors.transparent,
                      width: widget.onHold ? 2 : 0,
                    ),
                  ),
                  height: 83,
                  width: 83,
                  child: widget.thumbnailURL == null ||
                          widget.thumbnailURL!.isEmpty
                      ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: theme.disableColor,
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.thumbnailURL!,
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
              const SizedBox(height: 5),
              Text(
                (widget.name?.isNotEmpty ?? false) ? widget.name! : 'Untitled',
                style: widget.onHold
                    ? theme.textTheme.ppMori600Black12
                    : theme.textTheme.ppMori400Black12,
                overflow: TextOverflow.ellipsis,
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

  const AddPlayListItem({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 83,
            height: 83,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: theme.auLightGrey,
              ),
            ),
            child: Icon(
              AuIcon.add,
              color: theme.auLightGrey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'new_playlist'.tr(),
            style: theme.textTheme.ppMori400Black12,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
