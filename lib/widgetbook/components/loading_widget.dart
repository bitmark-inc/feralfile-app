import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

final loadingWidgetComponent = WidgetbookComponent(
  name: 'LoadingWidget',
  useCases: [
    WidgetbookUseCase(
      name: 'default',
      builder: useCaseLoadingWidget,
    ),
  ],
);

Widget useCaseLoadingWidget(BuildContext context) {
  return LoadingWidget();
}
