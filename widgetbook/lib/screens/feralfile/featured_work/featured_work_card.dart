import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock_data/mock_asset_token.dart';

WidgetbookUseCase featuredWorkCard() {
  return WidgetbookUseCase(
    name: 'Featured Work Card',
    builder: (context) {
      final tokenTitle = context.knobs.list(
          label: 'Featured work',
          options: MockAssetToken.all.map((e) => e.title).toList());
      final token = MockAssetToken.all
          .firstWhere((element) => element.title == tokenTitle);
      final width = context.knobs.double
          .slider(label: 'Width', min: 100, max: 500, initialValue: 300);
      final height = context.knobs.double
          .slider(label: 'Height', min: 100, max: 500, initialValue: 400);
      final imageSource = Size(width, height);
      return MultiBlocProvider(
        providers: [
          BlocProvider<IdentityBloc>.value(
            value: injector.get<IdentityBloc>(),
          ),
        ],
        child: FeaturedWorkCard(
          token: token,
          imageSize: imageSource,
          onTap: (context, assetToken) {},
        ),
      );
    },
  );
}
