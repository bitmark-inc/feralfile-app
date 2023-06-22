import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TutorialVideo extends StatefulWidget {
  static const String tag = "tutorial_video_page";
  final TutorialVideosPayload payload;

  const TutorialVideo({Key? key, required this.payload}) : super(key: key);

  @override
  State<TutorialVideo> createState() => _TutorialVideoState();
}

class _TutorialVideoState extends State<TutorialVideo> {
  YoutubePlayerController? _controller;
  late List<VideoData> _videoData;
  VideoData? _currentVideoData;
  double? _width;

  @override
  void initState() {
    super.initState();
    fetchVideosIds();
    _setVideoController(_currentVideoData!);
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _setVideoController(VideoData data) {
    _controller = YoutubePlayerController(
        params:
            const YoutubePlayerParams(showFullscreenButton: true, mute: true))
      ..onInit = () {
        _controller!.loadVideoById(videoId: data.id);
        _controller!.stopVideo();
      };
  }

  void fetchVideosIds() {
    _videoData = widget.payload.videos;
    _currentVideoData = _videoData.first;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _width ??= MediaQuery.of(context).size.width;
    if (_controller == null) {
      return const SizedBox();
    }
    return YoutubePlayerScaffold(
      controller: _controller!,
      builder: (context, player) {
        return Scaffold(
            appBar: getBackAppBar(context, title: "tutorial_videos".tr(),
                onBack: () {
              Navigator.of(context).pop();
            }),
            body: ListView(
              children: [player, SingleChildScrollView(child: _content())],
            ));
      },
    );
  }

  Widget _videoDescription(VideoData data) {
    final width = (_width ?? MediaQuery.of(context).size.width) - 151;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: width,
            child: Text(
              data.title,
              style: theme.textTheme.ppMori400Black16,
              maxLines: 5,
            )),
        const SizedBox(height: 15),
        SizedBox(
            width: width,
            child: Text(data.description,
                maxLines: 5, style: theme.textTheme.ppMori400Black12)),
      ],
    );
  }

  Widget _videoItem(VideoData data, StateSetter dataState,
      {bool isPlaying = false}) {
    return GestureDetector(
      onTap: () {
        _currentVideoData = data;
        _controller!.loadVideoById(videoId: _currentVideoData?.id ?? "");
        dataState(() {});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 106,
                  child: isPlaying
                      ? Image.asset(
                          "assets/images/playing_video_thumbnail.png",
                        )
                      : Image.network(
                          YoutubePlayerController.getThumbnail(
                              videoId: data.id, quality: ThumbnailQuality.high),
                        ),
                ),
                const SizedBox(width: 15),
                _videoDescription(data)
              ],
            ),
          ),
          addOnlyDivider()
        ],
      ),
    );
  }

  Widget _content() {
    return StatefulBuilder(
        builder: (BuildContext dataContext, StateSetter dataState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(15),
              child: _videoDescription(_currentVideoData!)),
          const SizedBox(height: 35),
          ..._videoData
              .map((video) => _videoItem(video, dataState,
                  isPlaying: video == _currentVideoData))
              .toList()
        ],
      );
    });
  }
}

class VideoData {
  final String id;
  final String title;
  final String description;

  const VideoData({
    required this.id,
    required this.title,
    required this.description,
  });

  // from json
  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

class TutorialVideosPayload {
  final List<VideoData> videos;

  const TutorialVideosPayload({required this.videos});
}
