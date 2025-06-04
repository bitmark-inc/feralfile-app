import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/view/exhibition_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock/mock_injector.dart';
import 'package:widgetbook_workspace/mock_data/mock_exhibition.dart';

WidgetbookUseCase exhibitionView() {
  return WidgetbookUseCase(
    name: 'Exhibition View',
    builder: (context) {
      return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: MockInjector.get<CanvasDeviceBloc>()),
          ],
          child: ExhibitionCard(
            exhibition: MockExhibitionData.evolvedFormulaeExhibition,
            viewableExhibitions: MockExhibitionData.listExhibition,
          ));
    },
  );
}
