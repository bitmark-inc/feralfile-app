import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/data/exhibition.dart';

class MockExhibitionData {
  static Exhibition get evolvedFormulaeExhibition =>
      Exhibition.fromJson(evolvedFormulaeExhibitionData);

  static Exhibition get patternsOfFlowExhibition =>
      Exhibition.fromJson(patternsOfFlowExhibitionData);

  static Exhibition get crawlExhibition =>
      Exhibition.fromJson(crawlExhibitionData);

  static List<Exhibition> get listExhibition => [
        evolvedFormulaeExhibition,
        patternsOfFlowExhibition,
        crawlExhibition,
      ];

  static List<Exhibition> getListExhibitionByStatus(int status) =>
      listExhibition.where((e) => e.status == status).toList();

  static List<Exhibition> getListExhibitionByType(String type) =>
      listExhibition.where((e) => e.type == type).toList();

  static List<Exhibition> getListExhibitionByArtist(String artistId) =>
      listExhibition
          .where((e) =>
              e.artistsAlumni?.any((artist) => artist.id == artistId) ?? false)
          .toList();

  static List<Exhibition> getListExhibitionByCurator(String curatorId) =>
      listExhibition
          .where((e) =>
              e.curatorsAlumni?.any((curator) => curator.id == curatorId) ??
              false)
          .toList();

  static Exhibition? getExhibitionById(String id) =>
      listExhibition.firstWhere((exhibition) => exhibition.id == id);
}
