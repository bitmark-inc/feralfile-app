import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_artwork.dart';

WidgetbookUseCase featuredWorkView() {
  return WidgetbookUseCase(
    name: 'Featured Work View',
    builder: (context) {
      final featureArtworks = MockArtwork.all;
      final ids = featureArtworks
          .map((artwork) => artwork.indexerTokenId)
          .toList()
          .where((id) => id != null)
          .cast<String>()
          .toList();
      return MultiBlocProvider(
        providers: [
          BlocProvider<IdentityBloc>.value(
            value: injector.get<IdentityBloc>(),
          ),
        ],
        child: FeaturedWorkView(
          tokenIDs: ids,
          header: Text('Featured Works'),
        ),
      );
    },
  );
}
