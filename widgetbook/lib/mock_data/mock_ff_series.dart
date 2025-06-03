import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';

class MockFFSeriesData {
  static FFSeries get series => FFSeries(
        'mock_series_1',
        'mock_artist_1',
        'mock_asset_1',
        'Mock Series 1',
        'mock-series-1',
        'image',
        'This is a mock series',
        'https://example.com/series1.jpg',
        'https://example.com/series1.jpg',
        'mock_exhibition_1',
        null,
        null,
        AlumniAccount(
          id: 'mock_artist_1',
          fullName: 'Mock Artist 1',
          slug: 'mock-artist-1',
        ),
        null,
        DateTime.now(),
        DateTime.now(),
        0,
        0,
        DateTime.now(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      );

  static FFSeries get seriesName1 => FFSeries(
        'mock_series_2',
        'mock_artist_2',
        'mock_asset_2',
        'Mock Series Name 1',
        'mock-series-name-1',
        'video',
        'This is another mock series',
        'https://example.com/series2.jpg',
        'https://example.com/series2.jpg',
        'mock_exhibition_2',
        null,
        null,
        AlumniAccount(
          id: 'mock_artist_2',
          fullName: 'Mock Artist 2',
          slug: 'mock-artist-2',
        ),
        null,
        DateTime.now(),
        DateTime.now(),
        1,
        1,
        DateTime.now(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      );

  static FFSeries get seriesName2 => FFSeries(
        'mock_series_3',
        'mock_artist_3',
        'mock_asset_3',
        'Mock Series Name 2',
        'mock-series-name-2',
        'image',
        'This is yet another mock series',
        'https://example.com/series3.jpg',
        'https://example.com/series3.jpg',
        'mock_exhibition_3',
        null,
        null,
        AlumniAccount(
          id: 'mock_artist_3',
          fullName: 'Mock Artist 3',
          slug: 'mock-artist-3',
        ),
        null,
        DateTime.now(),
        DateTime.now(),
        2,
        2,
        DateTime.now(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      );

  static List<FFSeries> get listSeries => [
        series,
        seriesName1,
        seriesName2,
      ];

  static List<FFSeries> getListSeriesByMedium(String medium) =>
      listSeries.where((s) => s.medium == medium).toList();

  static List<FFSeries> getListSeriesByArtist(String artistId) =>
      listSeries.where((s) => s.artistAlumniAccountID == artistId).toList();
}
