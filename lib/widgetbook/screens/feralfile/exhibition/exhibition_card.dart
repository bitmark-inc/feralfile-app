import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/view/exhibition_item.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_exhibition.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase exhibitionView() {
  return WidgetbookUseCase(
    name: 'Exhibition View',
    builder: (context) {
      final isSource = context.knobs.boolean(
        label: 'Is Source',
        initialValue: false,
      );
      final exhibition = (isSource)
          ? MockExhibitionData.sourceExhibition
          : MockExhibitionData.evolvedFormulaeExhibition;

      final exhibitionTitle = context.knobs.string(
        label: 'Exhibition Title',
        initialValue: exhibition.title,
      );

      final type = context.knobs.list(
        label: 'Exhibition Type',
        options: const [
          'solo',
          'group',
        ],
        initialOption: exhibition.type,
      );

      final customExhibition = exhibition.copyWith(
        title: exhibitionTitle,
        type: type,
      );

      return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: MockInjector.get<CanvasDeviceBloc>()),
          ],
          child: ExhibitionCard(
            exhibition: customExhibition,
            viewableExhibitions: MockExhibitionData.listExhibition,
          ));
    },
  );
}
