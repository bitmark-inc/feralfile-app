import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/account/test_artwork_screen.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class FFArtworkPreviewBloc
    extends AuBloc<FFArtworkPreviewEvent, FFArtworkPreviewState> {
  FFArtworkPreviewBloc() : super(FFArtworkPreviewState()) {
    on<FFArtworkPreviewConfigByArtwork>((event, emit) async {
      if (testArtworkMode) {
        emit(state.copyWith(
            mediumMap: {testArtworkPreviewURL!: testArtworkPreviewURL!}));
        return;
      }
      if (!state.mediumMap.containsKey(event.artwork.previewURL)) {
        final medium = await event.artwork.renderingType();
        final Map<String, String> mediumMap = {};
        mediumMap[event.artwork.previewURL] = medium;
        mediumMap.addEntries(state.mediumMap.entries);
        emit(state.copyWith(mediumMap: mediumMap));
      }
    });
  }
}
