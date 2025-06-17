import 'package:autonomy_flutter/screen/feralfile_home/list_alumni_view.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/index.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase alumniCardView() {
  return WidgetbookUseCase(
      name: 'Alumni View',
      builder: (context) {
        final alumni = MockAlumniData.listAll.first;
        final alias = context.knobs.string(
          label: 'Alias',
          initialValue: alumni.alias!,
        );

        return AlumniCard(
          alumni: alumni.copyWith(
            alias: alias,
          ),
        );
      });
}
