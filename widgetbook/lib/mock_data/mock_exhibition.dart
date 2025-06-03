import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'mock_alumni.dart';
import 'mock_ff_series.dart';

class MockExhibitionData {
  static Exhibition get exhibition1 => Exhibition(
        id: 'mock_exhibition_1',
        title: 'Mock Exhibition 1',
        slug: 'mock-exhibition-1',
        exhibitionStartAt: DateTime.now(),
        previewDuration: 7,
        noteTitle: 'Mock Note Title 1',
        noteBrief: 'This is a mock exhibition note brief',
        note: 'This is a mock exhibition note',
        mintBlockchain: 'ethereum',
        type: 'solo',
        status: 1,
        coverURI: 'https://example.com/exhibition1.jpg',
        coverDisplay: 'https://example.com/exhibition1.jpg',
        curatorAlumni: MockAlumniData.curator1,
        curatorsAlumni: [MockAlumniData.curator1],
        artistsAlumni: [MockAlumniData.artist1],
        series: [MockFFSeriesData.series],
        contracts: null,
        partnerAlumni: null,
        posts: null,
      );

  static Exhibition get exhibition2 => Exhibition(
        id: 'mock_exhibition_2',
        title: 'Mock Exhibition 2',
        slug: 'mock-exhibition-2',
        exhibitionStartAt: DateTime.now().add(const Duration(days: 30)),
        previewDuration: 14,
        noteTitle: 'Mock Note Title 2',
        noteBrief: 'This is another mock exhibition note brief',
        note: 'This is another mock exhibition note',
        mintBlockchain: 'tezos',
        type: 'group',
        status: 0,
        coverURI: 'https://example.com/exhibition2.jpg',
        coverDisplay: 'https://example.com/exhibition2.jpg',
        curatorAlumni: MockAlumniData.curator1,
        curatorsAlumni: [MockAlumniData.curator1],
        artistsAlumni: [MockAlumniData.artist1, MockAlumniData.artist2],
        series: [MockFFSeriesData.series, MockFFSeriesData.seriesName1],
        contracts: null,
        partnerAlumni: null,
        posts: null,
      );

  static Exhibition get exhibition3 => Exhibition(
        id: 'mock_exhibition_3',
        title: 'Mock Exhibition 3',
        slug: 'mock-exhibition-3',
        exhibitionStartAt: DateTime.now().add(const Duration(days: 60)),
        previewDuration: 30,
        noteTitle: 'Mock Note Title 3',
        noteBrief: 'This is yet another mock exhibition note brief',
        note: 'This is yet another mock exhibition note',
        mintBlockchain: 'ethereum',
        type: 'solo',
        status: 0,
        coverURI: 'https://example.com/exhibition3.jpg',
        coverDisplay: 'https://example.com/exhibition3.jpg',
        curatorAlumni: MockAlumniData.curator1,
        curatorsAlumni: [MockAlumniData.curator1],
        artistsAlumni: [MockAlumniData.artist2],
        series: [MockFFSeriesData.seriesName2],
        contracts: null,
        partnerAlumni: null,
        posts: null,
      );

  static List<Exhibition> get listExhibition => [
        exhibition1,
        exhibition2,
        exhibition3,
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
