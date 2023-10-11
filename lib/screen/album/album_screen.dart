import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/album/album_state.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/nft_collection.dart';

import 'album_bloc.dart';

enum AlbumType { artist, medium }

class AlbumScreenPayload {
  final AlbumType type;
  final AlbumModel album;
  final String filterStr;

  const AlbumScreenPayload(
      {required this.type, required this.album, required this.filterStr});
}

class AlbumScreen extends StatefulWidget {
  final AlbumScreenPayload payload;

  const AlbumScreen({super.key, required this.payload});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final _bloc = injector.get<AlbumBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(LoadAlbumEvent(
        type: widget.payload.type,
        id: widget.payload.album.id,
        filterStr: widget.payload.filterStr));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AlbumBloc, AlbumState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is AlbumInitState) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: CircularProgressIndicator());
        },
        listener: (context, state) {
          if (state is AlbumLoadedState &&
              state.nftLoadingState == NftLoadingState.done) {
            final id = widget.payload.album.id;
            final name = widget.payload.album.name;
            final tokenIDs = state.assetTokens?.map((e) => e.id).toList();
            final playlist = PlayListModel(
              id: id,
              name: name,
              tokenIDs: tokenIDs,
            );
            final albumType = widget.payload.type;
            final icon = albumType == AlbumType.medium
                ? SvgPicture.asset(MediumCategoryExt.icon(id),
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                        AppColor.primaryBlack, BlendMode.srcIn))
                : null;
            final collectionType = albumType == AlbumType.medium
                ? CollectionType.medium
                : CollectionType.artist;
            Navigator.of(context).pushReplacementNamed(
                AppRouter.viewPlayListPage,
                arguments: ViewPlaylistScreenPayload(
                    playListModel: playlist,
                    titleIcon: icon,
                    collectionType: collectionType));
          }
        },
      ),
    );
  }
}
