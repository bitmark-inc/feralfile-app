import 'package:autonomy_flutter/screen/feralfile_home/list_alumni_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase listAlumniView() {
  return WidgetbookUseCase(
    name: 'List Alumni View',
    builder: (context) => ListAlumniView(
      listAlumni: [],
      onAlumniSelected: (alumni) {},
      exploreBar: const Text('Explore'),
      header: const Text('Alumni'),
    ),
  );
}
