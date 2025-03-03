import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/indexer_collection/indexer_collection_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:http/http.dart' as http;
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';

class IndexerCollectionBloc
    extends AuBloc<IndexerCollectionEvent, IndexerCollectionState> {
  final FeralFileService _feralFileService;

  IndexerCollectionBloc(this._feralFileService)
      : super(IndexerCollectionState()) {
    on<IndexerCollectionGetCollectionEvent>((event, emit) async {
      final listAssetTokens = await injector<IndexerService>()
          .getCollectionListToken(event.collectionId);
      final thumbnailUrl = listAssetTokens.firstOrNull?.thumbnailURL;
      double thumbnailRatio = 1;
      if (thumbnailUrl != null) {
        thumbnailRatio = await _getImageRatio(thumbnailUrl);
      }
      emit(state.copyWith(
        assetTokens: listAssetTokens,
        thumbnailRatio: thumbnailRatio,
      ));
    });
  }

  Future<double> _getImageRatio(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(Uint8List.fromList(bytes), (image) {
        completer.complete(image);
      });
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.completeError('timeout');
        }
      });

      final image = await completer.future;
      return image.width / image.height;
    } catch (e) {
      return 1;
    }
  }
}
