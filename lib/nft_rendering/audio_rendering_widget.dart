import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:autonomy_flutter/nft_rendering/nft_error_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audional String? previewURL;
  final String? thumbnailURL;
  final bool isMute;
  final Function({int? time})? onLoaded;
  final Widget loadingWidget;
  final Widget errorWidget;

  const AudioNFTRenderingWidget({
    this.loadingWidget = const LoadingWidget(),
    this.errorWidget = const NFTErrorWidget(),
    super.key,
    this.previewURL,
    this.thumbnailURL,
    this.isMute = false,
    this.onLoaded,
  });

  @override
  State<AudioNFTRenderingWidget> createState() =>
      _AudioNFTRenderingWidgetState();
}

class _AudioNFTRenderingWidgetState
    extends NFTRenderingWidgetState<AudioNFTRenderingWidget> {
  AudioPlayer? _player;
  String? _thumbnailURL;
  final _progressStreamController = StreamController<double>();

  @override
  void initState() {
    super.initState();
    _thumbnailURL = widget.thumbnailURL;
    unawaited(_initializeAudioPlayer());
  }

  @override
  void dispose() {
    unawaited(_disposeAudioPlayer());
    unawaited(_progressStreamController.close());
    super.dispose();
  }

  Future<void> _initializeAudioPlayer() async {
    if (widget.previewURL != null) {
      await _playAudio(widget.previewURL!);
    }
  }

  Future<void> _playAudio(String audioURL) async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _player = AudioPlayer();
      _player?.positionStream.listen((event) {
        final progress =
            event.inMilliseconds / (_player?.duration?.inMilliseconds ?? 1);
        _progressStreamController.sink.add(progress);
      });

      await _player?.setLoopMode(LoopMode.all);
      await _player?.setAudioSource(AudioSource.uri(Uri.parse(audioURL)));
      if (widget.isMute) {
        await mute();
      }

      widget.onLoaded?.call(time: _player?.duration?.inSeconds);
      await _player?.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error while setting audio source: $audioURL. Error: $e');
      }
    }
  }

  Future<void> _disposeAudioPlayer() async {
    await _player?.dispose();
    _player = null;
  }

  Future<void> _pauseAudio() async {
    await _player?.pause();
  }

  Future<void> _resumeAudio() async {
    await _player?.play();
  }

  Future<void> pauseOrResume() async {
    if (_player?.playing == true) {
      await _pauseAudio();
    } else {
      await _resumeAudio();
    }
  }

  @override
  Future<void> mute() async {
    await _player?.setVolume(0);
  }

  @override
  Future<void> unmute() async {
    await _player?.setVolume(1);
  }

  @override
  Future<void> pause() async {
    await _pauseAudio();
  }

  @override
  Future<void> resume() async {
    await _resumeAudio();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _thumbnailURL != null
                ? Image.network(
                    _thumbnailURL!,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return widget.loadingWidget;
                    },
                    errorBuilder: (context, url, error) => widget.errorWidget,
                    fit: BoxFit.contain,
                  )
                : widget.errorWidget,
          ),
          StreamBuilder<double>(
            stream: _progressStreamController.stream,
            builder: (context, snapshot) => LinearProgressIndicator(
              value: snapshot.data ?? 0,
              color: const Color.fromRGBO(0, 255, 163, 1),
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      );
}
