import 'package:autonomy_flutter/model/ff_alumni.dart';

class MockAlumniData {
  static AlumniAccount get artist1 => AlumniAccount(
        id: 'mock_artist_1',
        fullName: 'Mock Artist 1',
        slug: 'mock-artist-1',
        isArtist: true,
        bio: 'This is a mock artist bio',
        avatarURI: 'https://example.com/artist1.jpg',
        avatarDisplay: 'https://example.com/artist1.jpg',
        location: 'New York',
        website: 'https://example.com/artist1',
        socialNetworks: SocialNetwork(
          instagramID: 'artist1',
          twitterID: 'artist1',
        ),
        addresses: AlumniAccountAddresses(
          ethereum: '0x1234567890abcdef',
          tezos: 'tz1abcdefghijklmnopqrstuvwxyz',
        ),
      );

  static AlumniAccount get artist2 => AlumniAccount(
        id: 'mock_artist_2',
        fullName: 'Mock Artist 2',
        slug: 'mock-artist-2',
        isArtist: true,
        bio: 'This is another mock artist bio',
        avatarURI: 'https://example.com/artist2.jpg',
        avatarDisplay: 'https://example.com/artist2.jpg',
        location: 'London',
        website: 'https://example.com/artist2',
        socialNetworks: SocialNetwork(
          instagramID: 'artist2',
          twitterID: 'artist2',
        ),
        addresses: AlumniAccountAddresses(
          ethereum: '0xabcdef1234567890',
          tezos: 'tz1zyxwvutsrqponmlkjihgfedcba',
        ),
      );

  static AlumniAccount get curator1 => AlumniAccount(
        id: 'mock_curator_1',
        fullName: 'Mock Curator 1',
        slug: 'mock-curator-1',
        isCurator: true,
        bio: 'This is a mock curator bio',
        avatarURI: 'https://example.com/curator1.jpg',
        avatarDisplay: 'https://example.com/curator1.jpg',
        location: 'Paris',
        website: 'https://example.com/curator1',
        socialNetworks: SocialNetwork(
          instagramID: 'curator1',
          twitterID: 'curator1',
        ),
        addresses: AlumniAccountAddresses(
          ethereum: '0x9876543210fedcba',
          tezos: 'tz1abcdefghijklmnopqrstuvwxyz',
        ),
      );

  static List<AlumniAccount> get listArtists => [
        artist1,
        artist2,
      ];

  static List<AlumniAccount> get listCurators => [
        curator1,
      ];

  static List<AlumniAccount> get listAll => [
        ...listArtists,
        ...listCurators,
      ];

  static AlumniAccount? getAlumniById(String id) =>
      listAll.firstWhere((alumni) => alumni.id == id);
}
