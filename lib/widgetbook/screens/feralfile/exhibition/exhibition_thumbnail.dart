import 'package:autonomy_flutter/view/exhibition_item.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_exhibition.dart';

WidgetbookUseCase exhibitionThumbnail() {
  return WidgetbookUseCase(
    name: 'Exhibition Thumbnail',
    builder: (context) => ExhibitionCard(
      exhibition: MockExhibitionData.evolvedFormulaeExhibition,
      viewableExhibitions: MockExhibitionData.listExhibition,
    ),
  );
}
