import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class FFArtworkPreviewBloc
    extends AuBloc<FFArtworkPreviewEvent, FFArtworkPreviewState> {
  FFArtworkPreviewBloc() : super(FFArtworkPreviewState()) {
    on<FFArtworkPreviewConfigByArtwork>((event, emit) async {
      final Map<String, String> mediumMap = Map.from(state.mediumMap);
      final Map<String, String> overriddenHtmlMap =
          Map.from(state.overriddenHtml);
      final shouldFetchRenderingType =
          !state.mediumMap.containsKey(event.artwork.previewURL);
      final shouldFetchFeralFileFrame = event.artwork.isFeralfileFrame &&
          !state.overriddenHtml.containsKey(event.artwork.id);
      if (shouldFetchRenderingType || shouldFetchFeralFileFrame) {
        if (shouldFetchRenderingType) {
          final medium = await event.artwork.renderingType();
          mediumMap[event.artwork.previewURL] = medium;
        }
        if (shouldFetchFeralFileFrame) {
          final contractAddress =
              event.artwork.series?.exhibition?.contracts?.firstOrNull?.address;
          final tokenId = event.artwork.id;
          final overriddenHtml =
              await fetchFeralFileFramePreview(contractAddress!, tokenId);
          if (overriddenHtml != null) {
            overriddenHtmlMap[event.artwork.id] = overriddenHtml;
          }
        }
        emit(
          state.copyWith(
            mediumMap: mediumMap,
            overriddenHtml: overriddenHtmlMap,
          ),
        );
      }
    });
  }
}
