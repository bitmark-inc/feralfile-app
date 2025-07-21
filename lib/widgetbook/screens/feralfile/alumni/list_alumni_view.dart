import 'package:autonomy_flutter/screen/feralfile_home/list_alumni_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/index.dart';

WidgetbookUseCase listAlumniView() {
  return WidgetbookUseCase(
    name: 'List Alumni View',
    builder: (context) => ListAlumniView(
      listAlumni: MockAlumniData.listAll,
      onAlumniSelected: (alumni) {},
      exploreBar: const SizedBox(),
      header: const SizedBox.shrink(),
    ),
  );
}
