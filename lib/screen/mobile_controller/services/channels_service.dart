import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';

class ChannelsService {
  static const List<Map<String, dynamic>> _mockData = [
    {
      'id': '1',
      'title': 'Feral File',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '2',
      'title': 'Art Blocks',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '3',
      'title': 'Aorist',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '4',
      'title': 'MoMA',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '5',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '6',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '7',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '8',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '9',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '10',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '11',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '12',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '13',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '14',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
    {
      'id': '15',
      'title': 'Tyler Hobbs',
      'description':
          'Lorem ipsum dolor sit amet consectetur. Facilisis ac sed urna nec. Ut velit venenatis dolor ultricies lobortis congue. Ut id consequat dignissim nunc justo aliquet nam proin. Eu tortor volutpat morbi ipsum placerat euismod.',
    },
  ];

  Future<List<Channel>> getChannels({int page = 0, int limit = 10}) async {
    // Simulate network delay
    final delayMs = 500 + (page * 200);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    final startIndex = page * limit;
    final endIndex = startIndex + limit;

    // Simulate finite data
    if (startIndex >= _mockData.length * 3) {
      return [];
    }

    final channels = <Channel>[];
    for (var i = startIndex; i < endIndex && i < _mockData.length; i++) {
      channels.add(Channel.fromJson(_mockData[i]));
    }

    return channels;
  }
}
