import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class ListPlaylistsScreen extends StatefulWidget {
  const ListPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<ListPlaylistsScreen> createState() => _ListPlaylistsScreenState();
}

class _ListPlaylistsScreenState extends State<ListPlaylistsScreen>
    with RouteAware, WidgetsBindingObserver {
  final ValueNotifier<List<PlayListModel>?> _playlists = ValueNotifier(null);
  final isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();

  Future<List<PlayListModel>?> _getPlaylist() async {
    final configurationService = injector.get<ConfigurationService>();
    if (isDemo) {
      return injector<VersionService>().getDemoAccountFromGithub();
    }
    return configurationService.getPlayList();
  }

  _initPlayList() async {
    _playlists.value = await _getPlaylist();
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
    if (isDemo) return;
    await injector
        .get<ConfigurationService>()
        .setPlayList(_playlists.value, override: true);
    injector.get<SettingsDataService>().backup();
  }

  @override
  void didPopNext() {
    _initPlayList();
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).viewPadding.top;
    final theme = Theme.of(context);
    final radio = (MediaQuery.of(context).size.width - 45) / 425;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeaderView(
              paddingTop: paddingTop,
              action: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: _gotoCreatePlaylist,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(64),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Text(
                      'new_playlist'.tr(),
                      style: theme.textTheme.ppMori400Black12,
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<List<PlayListModel>?>(
              valueListenable: _playlists,
              builder: (context, value, child) => ReorderableGridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                onDragStart: (index) {
                  Vibrate.feedback(FeedbackType.light);
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final element = value?.removeAt(oldIndex);
                    if (element != null) value?.insert(newIndex, element);
                    _onUpdatePlaylists();
                  });
                },
                header: isDemo || (_playlists.value?.isNotEmpty ?? true)
                    ? null
                    : [
                        AddPlayListItem(
                          onTap: _gotoCreatePlaylist,
                        )
                      ],
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: radio,
                dragWidgetBuilder: (index, child) => Scaffold(
                  body: PlaylistItem(
                    key: ValueKey(value?[index]),
                    name: value?[index].name,
                    thumbnailURL: value?[index].thumbnailURL,
                    onHold: true,
                    onSelected: () => Navigator.pushNamed(
                      context,
                      AppRouter.viewPlayListPage,
                      arguments: value?[index],
                    ).then((value) {
                      _initPlayList();
                    }),
                  ),
                ),
                children: value
                        ?.map(
                          (e) => PlaylistItem(
                            key: ValueKey(e),
                            name: e.name,
                            thumbnailURL: e.thumbnailURL,
                            // onHold: true,
                            onSelected: () => Navigator.pushNamed(
                              context,
                              AppRouter.viewPlayListPage,
                              arguments: e,
                            ),
                          ),
                        )
                        .toList() ??
                    [],
              ),
            ),
          ],
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
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: widget.onHold ? 3 : 0,
            color: theme.auSuperTeal,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 10),
              child: Text(
                (widget.name?.isNotEmpty ?? false) ? widget.name! : 'Untitled',
                style: theme.textTheme.ppMori400White12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                child: widget.thumbnailURL == null
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: theme.disableColor,
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.thumbnailURL ?? '',
                        fit: BoxFit.cover,
                        cacheManager: injector.get<CacheManager>(),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: theme.disableColor,
                        ),
                        memCacheHeight: 1000,
                        memCacheWidth: 1000,
                        maxWidthDiskCache: 1000,
                        maxHeightDiskCache: 1000,
                        fadeInDuration: Duration.zero,
                      ),
              ),
            ),
          ],
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: theme.colorScheme.primary,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'new_playlist'.tr(),
                style: theme.textTheme.ppMori400Black12,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.auLightGrey,
                    border: Border.all(color: theme.auLightGrey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Icon(
                        AuIcon.add,
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
