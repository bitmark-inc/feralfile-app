import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'mock_ff_series.dart';

class MockArtworkData {
  static Artwork get artwork1 => Artwork(
        'mock_artwork_1',
        'mock_series_1',
        1,
        'Mock Artwork 1',
        'image',
        '0x1234567890abcdef',
        false,
        false,
        'minted',
        false,
        'https://example.com/artwork1.jpg',
        'https://example.com/artwork1.jpg',
        'https://example.com/artwork1.jpg',
        {'default': 'https://example.com/artwork1.jpg'},
        null,
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        false,
        MockFFSeriesData.series,
        null,
        null,
      );

  static Artwork get artwork2 => Artwork(
        'mock_artwork_2',
        'mock_series_1',
        2,
        'Mock Artwork 2',
        'image',
        '0xabcdef1234567890',
        false,
        false,
        'minted',
        false,
        'https://example.com/artwork2.jpg',
        'https://example.com/artwork2.jpg',
        'https://example.com/artwork2.jpg',
        {'default': 'https://example.com/artwork2.jpg'},
        null,
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        false,
        MockFFSeriesData.series,
        null,
        null,
      );

  static Artwork get artwork3 => Artwork(
        'mock_artwork_3',
        'mock_series_2',
        1,
        'Mock Artwork 3',
        'video',
        '0x9876543210fedcba',
        false,
        false,
        'minted',
        false,
        'https://example.com/artwork3.jpg',
        'https://example.com/artwork3.jpg',
        'https://example.com/artwork3.jpg',
        {'default': 'https://example.com/artwork3.jpg'},
        null,
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        false,
        MockFFSeriesData.seriesName1,
        null,
        null,
      );

  static List<Artwork> get listArtwork => [
        artwork1,
        artwork2,
        artwork3,
      ];

  static List<Artwork> getListArtworkBySeries(String seriesId) =>
      listArtwork.where((a) => a.seriesID == seriesId).toList();

  static List<Artwork> getListArtworkByCategory(String category) =>
      listArtwork.where((a) => a.category == category).toList();

  static Artwork? getArtworkById(String id) =>
      listArtwork.firstWhere((artwork) => artwork.id == id);
}
