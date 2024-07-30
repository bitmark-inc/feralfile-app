import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class FFArtworkPreviewBloc
    extends AuBloc<FFArtworkPreviewEvent, FFArtworkPreviewState> {
  FFArtworkPreviewBloc() : super(FFArtworkPreviewState()) {
    on<FFArtworkPreviewConfigByArtwork>((event, emit) async {
      final medium = await event.artwork.renderingType();
      emit(state.copyWith(medium: medium));
    });
  }
}
