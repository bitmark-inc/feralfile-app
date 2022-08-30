import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:cast/cast.dart';
import 'package:flutter/material.dart';

enum AUCastDeviceType { Airplay, Chromecast }

class AUCastDevice {
  final AUCastDeviceType type;
  bool isActivated = false;
  final CastDevice? chromecastDevice;
  CastSession? chromecastSession;

  AUCastDevice(this.type, [this.chromecastDevice]);
}

class ArtworkPreviewPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkPreviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ArtworkPreviewPage> createState() => _ArtworkPreviewPageState();
}

class _ArtworkPreviewPageState extends State<ArtworkPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }
}
