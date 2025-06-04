import 'package:autonomy_flutter/screen/feralfile_home/list_alumni_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock_data/index.dart';

WidgetbookUseCase alumniCardView() {
  return WidgetbookUseCase(
    name: 'Alumni View',
    builder: (context) => AlumniCard(
      alumni: MockAlumniData.listAll.first,
    ),
  );
}
