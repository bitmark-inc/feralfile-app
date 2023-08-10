import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/album/album_state.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/nft_collection.dart';
import 'album_bloc.dart';

enum AlbumType { artist, medium }

class AlbumScreenPayload {
  final AlbumType type;
  final String? id;
  const AlbumScreenPayload({required this.type, this.id});
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
    _bloc.add(LoadAlbumEvent(type: widget.payload.type, id: widget.payload.id));
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
          if (state is AlbumLoadedState && state.nftLoadingState == NftLoadingState.done) {
            final id = widget.payload.id;
            final name = widget.payload.id;
            final tokenIDs = state.assetTokens?.map((e) => e.id).toList();
            final playlist = PlayListModel(
              id: id,
              name: name,
              tokenIDs: tokenIDs,
            );
            Navigator.of(context).pushReplacementNamed(AppRouter.viewPlayListPage, arguments: playlist);
          }
        },
      ),
    );
  }
}
