import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/explore_statistics_data.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/index.dart';

class MockFeralfileService extends FeralFileService {
  @override
  Future<FFSeries> getSeries(String id,
      {String? exhibitionID, bool includeFirstArtwork = false}) async {
    return FFSeries(
      id,
      'mock_artist_id',
      'mock_asset_id',
      'Mock Series',
      'mock-series',
      'mock-medium',
      'Mock Description',
      'https://example.com/image.jpg',
      'https://example.com/display.jpg',
      'mock_exhibition_id',
      {'mock_key': 'mock_value'},
      FFSeriesSettings('mock_sale_model', 100),
      null,
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
  }

  @override
  Future<List<FFSeries>> getListSeries(String exhibitionId,
      {bool includeFirstArtwork = false}) async {
    return [
      FFSeries(
        'mock_series_1',
        'mock_artist_id_1',
        'mock_asset_id_1',
        'Mock Series 1',
        'mock-series-1',
        'mock-medium',
        'Mock Description 1',
        'https://example.com/image1.jpg',
        'https://example.com/display1.jpg',
        'mock_exhibition_id',
        {'mock_key': 'mock_value'},
        FFSeriesSettings('mock_sale_model', 100),
        null,
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
      ),
      FFSeries(
        'mock_series_2',
        'mock_artist_id_2',
        'mock_asset_id_2',
        'Mock Series 2',
        'mock-series-2',
        'mock-medium',
        'Mock Description 2',
        'https://example.com/image2.jpg',
        'https://example.com/display2.jpg',
        'mock_exhibition_id',
        {'mock_key': 'mock_value'},
        FFSeriesSettings('mock_sale_model', 100),
        null,
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
      ),
    ];
  }

  @override
  Future<Exhibition?> getExhibitionFromTokenID(String artworkID) async {
    return Exhibition(
      id: 'mock_exhibition',
      title: 'Mock Exhibition',
      slug: 'mock-exhibition',
      exhibitionStartAt: DateTime.now(),
      previewDuration: 0,
      noteTitle: 'mock-note-title',
      noteBrief: 'mock-note-brief',
      note: 'mock-note',
      mintBlockchain: 'mock-blockchain',
      type: 'mock-type',
      status: 0,
      coverURI: 'https://example.com/cover.jpg',
      coverDisplay: 'https://example.com/display.jpg',
      curatorsAlumni: null,
      artistsAlumni: null,
      series: null,
      contracts: null,
      partnerAlumni: null,
      curatorAlumni: null,
      posts: null,
    );
  }

  @override
  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID) async {
    return FeralFileResaleInfo(
      exhibitionID,
      'mock_sale_type',
      0.1,
      0.4,
      0.4,
      0.05,
      0.05,
      DateTime.now(),
      DateTime.now(),
    );
  }

  @override
  Future<String?> getPartnerFullName(String exhibitionId) async {
    return 'Mock Partner';
  }

  @override
  Future<Exhibition> getExhibition(String id,
      {bool includeFirstArtwork = false}) async {
    return Exhibition(
      id: id,
      title: 'Mock Exhibition',
      slug: 'mock-exhibition',
      exhibitionStartAt: DateTime.now(),
      previewDuration: 0,
      noteTitle: 'Mock Note Title',
      noteBrief: 'Mock Note Brief',
      note: 'Mock Note',
      mintBlockchain: 'mock-blockchain',
      type: 'mock-type',
      status: 0,
      coverURI: 'https://example.com/cover.jpg',
      coverDisplay: 'https://example.com/display.jpg',
      curatorsAlumni: null,
      artistsAlumni: null,
      series: null,
      contracts: null,
      partnerAlumni: null,
      curatorAlumni: null,
      posts: null,
    );
  }

  @override
  Future<List<Exhibition>> getAllExhibitions({
    String keywork = '',
    int offset = 0,
    int limit = 20,
    bool includeFirstArtwork = false,
    Map<FilterType, FilterValue> filters = const {},
    List<String> relatedAlumniAccountIDs = const [],
    String sortBy = 'dateTime',
    String sortOrder = 'DESC',
  }) async {
    return [
      Exhibition(
        id: 'mock_exhibition_1',
        title: 'Mock Exhibition 1',
        slug: 'mock-exhibition-1',
        exhibitionStartAt: DateTime.now(),
        previewDuration: 0,
        noteTitle: 'Mock Note Title 1',
        noteBrief: 'Mock Note Brief 1',
        note: 'Mock Note 1',
        mintBlockchain: 'mock-blockchain',
        type: 'mock-type',
        status: 0,
        coverURI: 'https://example.com/cover1.jpg',
        coverDisplay: 'https://example.com/display1.jpg',
        curatorsAlumni: null,
        artistsAlumni: null,
        series: null,
        contracts: null,
        partnerAlumni: null,
        curatorAlumni: null,
        posts: null,
      ),
      Exhibition(
        id: 'mock_exhibition_2',
        title: 'Mock Exhibition 2',
        slug: 'mock-exhibition-2',
        exhibitionStartAt: DateTime.now(),
        previewDuration: 0,
        noteTitle: 'Mock Note Title 2',
        noteBrief: 'Mock Note Brief 2',
        note: 'Mock Note 2',
        mintBlockchain: 'mock-blockchain',
        type: 'mock-type',
        status: 0,
        coverURI: 'https://example.com/cover2.jpg',
        coverDisplay: 'https://example.com/display2.jpg',
        curatorsAlumni: null,
        artistsAlumni: null,
        series: null,
        contracts: null,
        partnerAlumni: null,
        curatorAlumni: null,
        posts: null,
      ),
    ];
  }

  @override
  Future<FeralFileListResponse<AlumniAccount>> getListAlumni({
    int limit = 20,
    int offset = 0,
    bool isArtist = false,
    bool isCurator = false,
    String keywork = '',
    String orderBy = 'relevance',
    String sortOrder = 'DESC',
  }) async {
    return FeralFileListResponse(
      result: [
        AlumniAccount(
          id: 'mock_alumni_1',
          alias: 'mock-alumni-1',
          slug: 'mock-alumni-1',
          fullName: 'Mock Alumni 1',
          isArtist: true,
          isCurator: false,
          bio: 'Mock Bio 1',
          email: 'mock1@example.com',
          avatarURI: 'https://example.com/avatar1.jpg',
          avatarDisplay: 'https://example.com/avatar1.jpg',
          location: 'Mock Location 1',
          website: 'https://example.com/1',
          company: 'Mock Company 1',
          socialNetworks: SocialNetwork(
            instagramID: 'mock1',
            twitterID: 'mock1',
          ),
          addresses: AlumniAccountAddresses(
            ethereum: '0x123',
            tezos: 'tz1',
            bitmark: 'bitmark1',
          ),
          associatedAddresses: ['0x123', 'tz1'],
          collaborationAlumniAccounts: null,
        ),
        AlumniAccount(
          id: 'mock_alumni_2',
          alias: 'mock-alumni-2',
          slug: 'mock-alumni-2',
          fullName: 'Mock Alumni 2',
          isArtist: false,
          isCurator: true,
          bio: 'Mock Bio 2',
          email: 'mock2@example.com',
          avatarURI: 'https://example.com/avatar2.jpg',
          avatarDisplay: 'https://example.com/avatar2.jpg',
          location: 'Mock Location 2',
          website: 'https://example.com/2',
          company: 'Mock Company 2',
          socialNetworks: SocialNetwork(
            instagramID: 'mock2',
            twitterID: 'mock2',
          ),
          addresses: AlumniAccountAddresses(
            ethereum: '0x456',
            tezos: 'tz2',
            bitmark: 'bitmark2',
          ),
          associatedAddresses: ['0x456', 'tz2'],
          collaborationAlumniAccounts: null,
        ),
      ],
      paging: Paging(
        offset: offset,
        limit: limit,
        total: 2,
      ),
    );
  }

  @override
  Future<List<Post>> getPosts({
    String sortBy = 'dateTime',
    String sortOrder = 'DESC',
    List<String> types = const [],
    List<String> relatedAlumniAccountIDs = const [],
    bool includeExhibition = true,
  }) async {
    return [
      Post(
        id: 'mock_post_1',
        type: 'mock_type',
        slug: 'mock-post-1',
        title: 'Mock Post 1',
        content: 'mock-content-1',
        coverURI: 'https://example.com/image1.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        exhibition: null,
      ),
      Post(
        id: 'mock_post_2',
        type: 'mock_type',
        slug: 'mock-post-2',
        title: 'Mock Post 2',
        content: 'mock-content-2',
        coverURI: 'https://example.com/image2.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        exhibition: null,
      ),
    ];
  }

  @override
  Future<Exhibition> getSourceExhibition() async {
    return Exhibition(
      id: 'mock_source_exhibition',
      title: 'Mock Source Exhibition',
      slug: 'mock-source-exhibition',
      exhibitionStartAt: DateTime.now(),
      previewDuration: 0,
      noteTitle: 'mock-note-title',
      noteBrief: 'mock-note-brief',
      note: 'mock-note',
      mintBlockchain: 'mock-blockchain',
      type: 'mock-type',
      status: 0,
      coverURI: 'https://example.com/cover.jpg',
      coverDisplay: 'https://example.com/display.jpg',
      curatorsAlumni: null,
      artistsAlumni: null,
      series: null,
      contracts: null,
      partnerAlumni: null,
      curatorAlumni: null,
      posts: null,
    );
  }

  @override
  Future<Exhibition?> getUpcomingExhibition() async {
    return Exhibition(
      id: 'mock_upcoming_exhibition',
      title: 'Mock Upcoming Exhibition',
      slug: 'mock-upcoming-exhibition',
      exhibitionStartAt: DateTime.now(),
      previewDuration: 0,
      noteTitle: 'mock-note-title',
      noteBrief: 'mock-note-brief',
      note: 'mock-note',
      mintBlockchain: 'mock-blockchain',
      type: 'mock-type',
      status: 0,
      coverURI: 'https://example.com/cover.jpg',
      coverDisplay: 'https://example.com/display.jpg',
      curatorsAlumni: null,
      artistsAlumni: null,
      series: null,
      contracts: null,
      partnerAlumni: null,
      curatorAlumni: null,
      posts: null,
    );
  }

  @override
  Future<Exhibition> getFeaturedExhibition() async {
    return Exhibition(
      id: 'mock_featured_exhibition',
      title: 'Mock Featured Exhibition',
      slug: 'mock-featured-exhibition',
      exhibitionStartAt: DateTime.now(),
      previewDuration: 0,
      noteTitle: 'mock-note-title',
      noteBrief: 'mock-note-brief',
      note: 'mock-note',
      mintBlockchain: 'mock-blockchain',
      type: 'mock-type',
      status: 0,
      coverURI: 'https://example.com/cover.jpg',
      coverDisplay: 'https://example.com/display.jpg',
      curatorsAlumni: null,
      artistsAlumni: null,
      series: null,
      contracts: null,
      partnerAlumni: null,
      curatorAlumni: null,
      posts: null,
    );
  }

  @override
  Future<List<Exhibition>> getOngoingExhibitions() async {
    return [
      Exhibition(
        id: 'mock_ongoing_exhibition_1',
        title: 'Mock Ongoing Exhibition 1',
        slug: 'mock-ongoing-exhibition-1',
        exhibitionStartAt: DateTime.now(),
        previewDuration: 0,
        noteTitle: 'mock-note-title-1',
        noteBrief: 'mock-note-brief-1',
        note: 'mock-note-1',
        mintBlockchain: 'mock-blockchain',
        type: 'mock-type',
        status: 0,
        coverURI: 'https://example.com/cover1.jpg',
        coverDisplay: 'https://example.com/display1.jpg',
        curatorsAlumni: null,
        artistsAlumni: null,
        series: null,
        contracts: null,
        partnerAlumni: null,
        curatorAlumni: null,
        posts: null,
      ),
      Exhibition(
        id: 'mock_ongoing_exhibition_2',
        title: 'Mock Ongoing Exhibition 2',
        slug: 'mock-ongoing-exhibition-2',
        exhibitionStartAt: DateTime.now(),
        previewDuration: 0,
        noteTitle: 'mock-note-title-2',
        noteBrief: 'mock-note-brief-2',
        note: 'mock-note-2',
        mintBlockchain: 'mock-blockchain',
        type: 'mock-type',
        status: 0,
        coverURI: 'https://example.com/cover2.jpg',
        coverDisplay: 'https://example.com/display2.jpg',
        curatorsAlumni: null,
        artistsAlumni: null,
        series: null,
        contracts: null,
        partnerAlumni: null,
        curatorAlumni: null,
        posts: null,
      ),
    ];
  }

  @override
  Future<List<Artwork>> getFeaturedArtworks() async {
    return [
      Artwork(
        'mock_artwork_1',
        'mock_series_id',
        0,
        'Mock Artwork 1',
        'Artwork category 1',
        'ownerAccountID',
        null,
        null,
        'blockchainStatus',
        false,
        'https://example.com/image1.jpg',
        'https://example.com/display1.jpg',
        'https://example.com/preview1.jpg',
        {},
        {'mock_key': 'mock_value'},
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        null,
        null,
        null,
        null,
      ),
      Artwork(
        'mock_artwork_2',
        'mock_series_id',
        1,
        'Mock Artwork 2',
        'Artwork category 2',
        'ownerAccountID',
        null,
        null,
        'blockchainStatus',
        false,
        'https://example.com/image2.jpg',
        'https://example.com/display2.jpg',
        'https://example.com/preview2.jpg',
        {},
        {'mock_key': 'mock_value'},
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        null,
        null,
        null,
        null,
      ),
    ];
  }

  @override
  Future<FeralFileListResponse<Artwork>> getSeriesArtworks(
    String seriesId,
    String exhibitionID, {
    bool withSeries = false,
    int offset = FeralFileService.offset,
    int limit = FeralFileService.limit,
  }) async {
    return FeralFileListResponse(
      result: [
        Artwork(
          'mock_artwork_1',
          seriesId,
          0,
          'Mock Artwork 1',
          'Artwork category 1',
          'ownerAccountID',
          null,
          null,
          'blockchainStatus',
          false,
          'https://example.com/image1.jpg',
          'https://example.com/display1.jpg',
          'https://example.com/preview1.jpg',
          {},
          {'mock_key': 'mock_value'},
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
          null,
          null,
          null,
          null,
        ),
        Artwork(
          'mock_artwork_2',
          seriesId,
          1,
          'Mock Artwork 2',
          'Artwork category 2',
          'ownerAccountID',
          null,
          null,
          'blockchainStatus',
          false,
          'https://example.com/image2.jpg',
          'https://example.com/display2.jpg',
          'https://example.com/preview2.jpg',
          {},
          {'mock_key': 'mock_value'},
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
          null,
          null,
          null,
          null,
        ),
      ],
      paging: Paging(
        offset: offset,
        limit: limit,
        total: 2,
      ),
    );
  }

  @override
  Future<Artwork?> getFirstViewableArtwork(String seriesId) async {
    return Artwork(
      'mock_artwork',
      seriesId,
      0,
      'Mock Artwork',
      'Artwork category',
      'ownerAccountID',
      null,
      null,
      'blockchainStatus',
      false,
      'https://example.com/image.jpg',
      'https://example.com/display.jpg',
      'https://example.com/preview.jpg',
      {},
      {'mock_key': 'mock_value'},
      DateTime.now(),
      DateTime.now(),
      DateTime.now(),
      null,
      null,
      null,
      null,
    );
  }

  @override
  Future<Artwork> getArtwork(String artworkId) async {
    return Artwork(
      artworkId,
      'mock_series_id',
      0,
      'Mock Artwork',
      'Artwork category',
      'ownerAccountID',
      null,
      null,
      'blockchainStatus',
      false,
      'https://example.com/image.jpg',
      'https://example.com/display.jpg',
      'https://example.com/preview.jpg',
      {},
      {'mock_key': 'mock_value'},
      DateTime.now(),
      DateTime.now(),
      DateTime.now(),
      null,
      null,
      null,
      null,
    );
  }

  @override
  Future<DailyToken?> getCurrentDailiesToken() async {
    return DailyToken(
      displayTime: DateTime.now(),
      blockchain: 'mock-blockchain',
      contractAddress: 'mock-contract-address',
      tokenID: 'mock-token-id',
      dailyNote: 'Mock Description',
      artwork: Artwork(
        'mock-artwork-id',
        'mock-series-id',
        1,
        'Mock Artwork Title',
        '',
        null,
        null,
        null,
        '',
        false,
        'https://example.com/image.jpg',
        null,
        'https://example.com/preview.html',
        {},
        {},
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        null,
        null,
        null,
        null,
      ),
    );
  }

  @override
  Future<List<DailyToken>> getUpcomingDailyTokens({
    String? startDate,
    int offset = 0,
    int limit = 3,
  }) async {
    return [
      DailyToken(
        displayTime: DateTime.now(),
        blockchain: 'mock-blockchain',
        contractAddress: 'mock-contract-address',
        tokenID: 'mock-token-id-1',
        dailyNote: 'Mock Description 1',
        artwork: Artwork(
          'mock-artwork-id-1',
          'mock-series-id-1',
          1,
          'Mock Artwork Title 1',
          '',
          null,
          null,
          null,
          '',
          false,
          'https://example.com/image1.jpg',
          null,
          'https://example.com/preview1.html',
          {},
          {},
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
          null,
          null,
          null,
          null,
        ),
      ),
      DailyToken(
        displayTime: DateTime.now(),
        blockchain: 'mock-blockchain',
        contractAddress: 'mock-contract-address',
        tokenID: 'mock-token-id-2',
        dailyNote: 'Mock Description 2',
        artwork: Artwork(
          'mock-artwork-id-2',
          'mock-series-id-2',
          2,
          'Mock Artwork Title 2',
          '',
          null,
          null,
          null,
          '',
          false,
          'https://example.com/image2.jpg',
          null,
          'https://example.com/preview2.html',
          {},
          {},
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
          null,
          null,
          null,
          null,
        ),
      ),
    ];
  }

  @override
  Future<FeralFileListResponse<FFSeries>> exploreArtworks({
    String? sortBy,
    String? sortOrder,
    String keyword = '',
    int limit = 300,
    int offset = 0,
    bool includeArtist = true,
    bool includeExhibition = true,
    bool includeFirstArtwork = true,
    bool onlyViewable = true,
    List<String> artistIds = const [],
    bool includeUniqeFilePath = true,
    Map<FilterType, FilterValue> filters = const {},
  }) async {
    return FeralFileListResponse(
      result: [
        FFSeries(
          'mock_series_1',
          'mock_artist_id_1',
          'mock_asset_id_1',
          'Mock Series 1',
          'mock-series-1',
          'mock-medium',
          'Mock Description 1',
          'https://example.com/image1.jpg',
          'https://example.com/display1.jpg',
          'mock_exhibition_id',
          {'mock_key': 'mock_value'},
          FFSeriesSettings('mock_sale_model', 100),
          null,
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
        ),
        FFSeries(
          'mock_series_2',
          'mock_artist_id_2',
          'mock_asset_id_2',
          'Mock Series 2',
          'mock-series-2',
          'mock-medium',
          'Mock Description 2',
          'https://example.com/image2.jpg',
          'https://example.com/display2.jpg',
          'mock_exhibition_id',
          {'mock_key': 'mock_value'},
          FFSeriesSettings('mock_sale_model', 100),
          null,
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
        ),
      ],
      paging: Paging(
        offset: offset,
        limit: limit,
        total: 2,
      ),
    );
  }

  @override
  Future<AlumniAccount> getAlumniDetail(String alumniId) async {
    return MockAlumniData.driessensVerstappen;
  }

  @override
  Future<ExploreStatisticsData> getExploreStatistics({
    bool unique = true,
    bool excludedFF = true,
  }) async {
    return ExploreStatisticsData(
      exhibition: 20,
      artwork: 100,
      artist: 50,
      curator: 30,
    );
  }

  @override
  Future<List<String>> getIndexerAssetIdsFromSeries(String seriesId) async {
    return [];
  }
}
