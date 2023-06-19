import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TutorialVideo extends StatefulWidget {
  static const String tag = "tutorial_video_page";

  const TutorialVideo({Key? key}) : super(key: key);

  @override
  State<TutorialVideo> createState() => _TutorialVideoState();
}

class _TutorialVideoState extends State<TutorialVideo> {
  YoutubePlayerController? _controller;
  bool _isFullScreen = false;
  late List<VideoData> videoData;
  late VideoData currentVideoData;

  @override
  void initState() {
    super.initState();
    fetchVideosIds().then((_) {
      _controller = YoutubePlayerController(
          params: const YoutubePlayerParams(showFullscreenButton: true))
        ..onInit = () {
          _controller!.loadVideoById(videoId: currentVideoData.id);
        };
      _controller!.onFullscreenChange = (value) {
        setState(() {
          _isFullScreen = value;
        });
      };
    });
  }

  Future<void> fetchVideosIds() async {
    await Future.delayed(const Duration(seconds: 1), () {
      videoData = [
        VideoData(
          id: "yRlwOdCK7Ho",
          title: "video_tutorials 1".tr(),
          description: "video_tutorials 2dddddd dssdssd sdsddssd".tr(),
        ),
        VideoData(
          id: "q4x2G_9-Mu0",
          title: "video_tutorials".tr(),
          description:
              "video_tutorials video_tutorials 2dddddd dssdssd sdsddssd".tr(),
        ),
        VideoData(
          id: "cq34RWXegM8",
          title: "video_tutorials".tr(),
          description:
          "video_tutorials video_tutorials 2dddddd dssdssd sdsddssd".tr(),
        ),
      ];
    });
    currentVideoData = videoData.first;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : getBackAppBar(context, title: "video_tutorials".tr(), onBack: () {
              Navigator.of(context).pop();
            }),
      body: _controller == null
          ? const SizedBox()
          : YoutubePlayerScaffold(
              controller: _controller!,
              builder: (context, player) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      player,
                    ],
                  ),
                );
              },
            ),
    );
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

  // from json factory
  factory VideoData.fromRawData(dynamic rawData) {
    final data = rawData as Map<String, dynamic>;
    return VideoData(
      id: data['id'],
      title: data['title'],
      description: data['description'],
    );
  }
}
