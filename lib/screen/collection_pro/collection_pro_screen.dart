import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/album/album_screen.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/screen/playlists/list_playlists/list_playlists.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';

class CollectionPro extends StatefulWidget {
  final List<CompactedAssetToken> tokens;
  const CollectionPro({super.key, required this.tokens});

  @override
  State<CollectionPro> createState() => CollectionProState();
}

class CollectionProState extends State<CollectionPro>
    with RouteAware, WidgetsBindingObserver {
  final _bloc = injector.get<CollectionProBloc>();
  final controller = ScrollController();
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    loadCollection();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  loadCollection() {
    _bloc.add(LoadCollectionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder(
        bloc: _bloc,
        builder: (context, state) {
          if (state is CollectionLoadedState) {
            final listAlbumByMedium = state.listAlbumByMedium;
            final listAlbumByArtist = state.listAlbumByArtist;
            final paddingTop = MediaQuery.of(context).viewPadding.top;
            return CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: HeaderView(paddingTop: paddingTop),
                ),
                const SliverToBoxAdapter(
                  child: CollectionSection(),
                ),
                SliverToBoxAdapter(
                  child: MediumSection(
                    listAlbumByMedium: listAlbumByMedium,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
                SliverToBoxAdapter(
                  child: AlbumByArtistSection(
                    listAlbumByArtist: listAlbumByArtist,
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class MediumSection extends StatefulWidget {
  final List<AlbumModel>? listAlbumByMedium;
  const MediumSection({super.key, required this.listAlbumByMedium});
  @override
  State<MediumSection> createState() => MediumSectionState();
}

class MediumSectionState extends State<MediumSection> {
  Widget _item(AlbumModel album) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.albumPage,
          arguments: AlbumScreenPayload(
            type: AlbumType.medium,
            id: album.id,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            SvgPicture.asset(
              "assets/images/medium_image.svg",
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 33),
            Text(album.name ?? ''),
            const Spacer(),
            Text('${album.total}'),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int total) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Medium',
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        Text(
          '$total',
          style: theme.textTheme.ppMori400Black14,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAlbumByMedium = widget.listAlbumByMedium;
    if (listAlbumByMedium == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, listAlbumByMedium.length),
        addDivider(color: AppColor.primaryBlack),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listAlbumByMedium.length,
          itemBuilder: (context, index) {
            final album = listAlbumByMedium[index];
            return _item(album);
          },
          separatorBuilder: (BuildContext context, int index) {
            return addDivider();
          },
        ),
      ],
    );
  }
}

class AlbumByArtistSection extends StatefulWidget {
  final List<AlbumModel>? listAlbumByArtist;
  const AlbumByArtistSection({super.key, required this.listAlbumByArtist});
  @override
  State<AlbumByArtistSection> createState() => _AlbumByArtistSectionState();
}

class _AlbumByArtistSectionState extends State<AlbumByArtistSection> {
  Widget _header(BuildContext context, int total) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Medium',
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        Text(
          '$total',
          style: theme.textTheme.ppMori400Black14,
        ),
      ],
    );
  }

  Widget _item(AlbumModel album) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.albumPage,
          arguments: AlbumScreenPayload(
            type: AlbumType.artist,
            id: album.id,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: album.thumbnailURL ?? "",
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                album.name ?? album.id,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(
              width: 24,
            ),
            Text('${album.total}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAlbumByArtist = widget.listAlbumByArtist;
    if (listAlbumByArtist == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, listAlbumByArtist.length),
        addDivider(color: AppColor.primaryBlack),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listAlbumByArtist.length,
          itemBuilder: (context, index) {
            final album = listAlbumByArtist[index];
            return _item(album);
          },
          separatorBuilder: (BuildContext context, int index) {
            return addDivider();
          },
        ),
      ],
    );
  }
}

class CollectionSection extends StatefulWidget {
  const CollectionSection({super.key});
  @override
  State<CollectionSection> createState() => _CollectionSectionState();
}

class _CollectionSectionState extends State<CollectionSection> {
  Widget _header(BuildContext context, int total) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Collections',
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        Text(
          '$total',
          style: theme.textTheme.ppMori400Black14,
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            _gotoCreatePlaylist(context);
          },
          child: const Icon(
            AuIcon.add,
            size: 22,
            color: AppColor.primaryBlack,
          ),
        ),
      ],
    );
  }

  void _gotoCreatePlaylist(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final playlists = injector<ConfigurationService>().getPlayList();
    final playlistIDsString = playlists.map((e) => e.id).toList().join();
    final playlistKeyBytes = utf8.encode(playlistIDsString);
    final playlistKey = sha256.convert(playlistKeyBytes).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, playlists.length),
        addDivider(color: AppColor.primaryBlack),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: ListPlaylistsScreen(
            key: Key(playlistKey),
          ),
        )
      ],
    );
  }
}
