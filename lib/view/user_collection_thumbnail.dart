import 'dart:async';

import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/indexer_collection/indexer_collection_page.dart';
import 'package:autonomy_flutter/util/feralfile_alumni_ext.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/user_collection.dart';

class UserCollectionThumnbail extends StatefulWidget {
  final UserCollection collection;
  final AlumniAccount? artist;

  const UserCollectionThumnbail(
      {required this.collection, required this.artist, super.key});

  @override
  State<UserCollectionThumnbail> createState() =>
      _UserCollectionThumnbailState();
}

class _UserCollectionThumnbailState extends State<UserCollectionThumnbail> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final artist = widget.artist;
    return _navigating
        ? const LoadingWidget()
        : GestureDetector(
            onTap: () async {
              await _gotoCollectionDetails(context, collection);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FFCacheNetworkImage(
                          imageUrl: collection.thumbnailURL,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _seriesInfo(context, collection, artist),
              ],
            ),
          );
  }

  Future<void> _gotoCollectionDetails(
      BuildContext context, UserCollection userCollection) async {
    if (userCollection.items == 1) {
    } else {
      unawaited(Navigator.of(context).pushNamed(
        AppRouter.indexerCollectionPage,
        arguments: IndexerCollectionPagePayload(
          collection: userCollection,
          artist: widget.artist,
        ),
      ));
    }
  }

  Widget _seriesInfo(
      BuildContext context, UserCollection collection, AlumniAccount? artist) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.ppMori400White12;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                artist?.displayAlias ?? '',
                style: defaultStyle,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                collection.name,
                style: defaultStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}
