import 'package:autonomy_flutter/view/header.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

final headerViewComponent = WidgetbookComponent(
  name: 'HeaderView',
  useCases: [
    WidgetbookUseCase(
      name: 'default',
      builder: useCaseHeaderView,
    ),
  ],
);

Widget useCaseHeaderView(BuildContext context) {
  return HeaderView(
    title: context.knobs.string(label: 'Title', initialValue: 'Title'),
    padding: context.knobs
        .listOrNull(label: 'Padding', options: [null, EdgeInsets.all(12)]),
    action: const SizedBox.shrink(),
  );
}
