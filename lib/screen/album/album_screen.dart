import 'package:autonomy_flutter/common/injector.dart';
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

          if (state is AlbumLoadedState) {
            return NftCollectionGrid(
              state: state.nftLoadingState,
              tokens: state.assetTokens ?? [],
              itemViewBuilder: (context, asset) => GestureDetector(
                onTap: () {
                  final accountIdentities = [asset.identity];
                  final payload = ArtworkDetailPayload(
                    accountIdentities,
                    0,
                  );
                  Navigator.of(context).pushNamed(
                    AppRouter.artworkDetailsPage,
                    arguments: payload,
                  );
                },
                child: tokenGalleryThumbnailWidget(
                  context,
                  asset,
                  1000,
                  useHero: false,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
        listener: (context, state) {},
      ),
    );
  }
}
