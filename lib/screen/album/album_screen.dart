import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/album/album_state.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/nft_collection.dart';

import 'album_bloc.dart';

enum AlbumType { artist, medium }

class AlbumScreenPayload {
  final AlbumType type;
  final AlbumModel album;

  const AlbumScreenPayload({required this.type, required this.album});
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
    _bloc.add(
        LoadAlbumEvent(type: widget.payload.type, id: widget.payload.album.id));
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
            Navigator.of(context).pushReplacementNamed(
                AppRouter.viewPlayListPage,
                arguments: ViewPlaylistScreenPayload(
                    playListModel: playlist, editable: false));
          }
        },
      ),
    );
  }
}
