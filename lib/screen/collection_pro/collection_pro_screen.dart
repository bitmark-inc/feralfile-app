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
                  child: AlbumSection(
                    listAlbum: listAlbumByMedium,
                    albumType: AlbumType.medium,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
                SliverToBoxAdapter(
                  child: AlbumSection(
                    listAlbum: listAlbumByArtist,
                    albumType: AlbumType.artist,
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

class Header extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget? icon;
  final Function()? onTap;
  const Header({
    super.key,
    required this.title,
    this.subTitle,
    this.icon,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        if (subTitle != null)
          Text(
            subTitle!,
            style: theme.textTheme.ppMori400Black14,
          ),
        if (icon != null) ...[
          const SizedBox(width: 15),
          GestureDetector(onTap: onTap, child: icon!)
        ],
      ],
    );
  }
}

class AlbumSection extends StatefulWidget {
  final List<AlbumModel>? listAlbum;
  final AlbumType albumType;
  const AlbumSection(
      {super.key, required this.listAlbum, required this.albumType});
  @override
  State<AlbumSection> createState() => _AlbumSectionState();
}

class _AlbumSectionState extends State<AlbumSection> {
  Widget _header(BuildContext context, int total) {
    final title = widget.albumType == AlbumType.medium ? 'Medium' : 'Artist';
    return Header(title: title, subTitle: "$total");
  }

  Widget _icon(AlbumModel album) {
    switch (widget.albumType) {
      case AlbumType.medium:
        return SvgPicture.asset(
          "assets/images/medium_image.svg",
          width: 42,
          height: 42,
        );
      case AlbumType.artist:
        return CachedNetworkImage(
          imageUrl: album.thumbnailURL ?? "",
          width: 42,
          height: 42,
        );
    }
  }

  Widget _item(BuildContext context, AlbumModel album) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.albumPage,
          arguments: AlbumScreenPayload(
            type: widget.albumType,
            id: album.id,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _icon(album),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                album.name ?? album.id,
                style: theme.textTheme.ppMori400Black14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${album.total}', style: theme.textTheme.ppMori400Grey12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAlbum = widget.listAlbum;
    final padding = 15.0;
    if (listAlbum == null) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, listAlbum.length),
          addDivider(color: AppColor.primaryBlack),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listAlbum.length,
            itemBuilder: (context, index) {
              final album = listAlbum[index];
              return _item(context, album);
            },
            separatorBuilder: (BuildContext context, int index) {
              return addDivider();
            },
          ),
        ],
      ),
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
    return Header(
      title: "Collections",
      subTitle: "$total",
      icon: const Icon(
        AuIcon.add,
        size: 22,
        color: AppColor.primaryBlack,
      ),
      onTap: () {
        _gotoCreatePlaylist(context);
      },
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              _header(context, playlists.length),
              addDivider(color: AppColor.primaryBlack),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Container(
            height: 200,
            width: 400,
            child: ListPlaylistsScreen(
              key: Key(playlistKey),
            ),
          ),
        )
      ],
    );
  }
}
