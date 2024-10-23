import 'package:autonomy_flutter/nft_rendering/audio_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/gif_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/image_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/pdf_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/svg_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/video_player_widget.dart';
import 'package:autonomy_flutter/nft_rendering/webview_rendering_widget.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestArtworkScreen extends StatefulWidget {
  const TestArtworkScreen({super.key});

  @override
  State<TestArtworkScreen> createState() => _TestArtworkScreenState();
}

class _TestArtworkScreenState extends State<TestArtworkScreen> {
  final _renderingTypes = [
    RenderingTypeExtension.auto,
    RenderingType.audio,
    RenderingType.gif,
    RenderingType.image,
    RenderingType.modelViewer,
    RenderingType.pdf,
    RenderingType.svg,
    RenderingType.video,
    RenderingType.webview,
  ];
  final _urlController = TextEditingController();
  String _renderingType = RenderingTypeExtension.auto;
  Widget? _renderingWidget;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(context, onBack: () {
          Navigator.pop(context);
        }, title: 'test_artwork'.tr()),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AuTextField(
                    controller: _urlController,
                    title: '',
                    onChanged: (valueChanged) {},
                  ),
                  DropdownButton<String>(
                      value: _renderingType,
                      items: _renderingTypes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _renderingType = value ?? RenderingTypeExtension.auto;
                        });
                      }),
                  PrimaryAsyncButton(
                    onTap: () async {
                      if (_urlController.text.isNotEmpty &&
                          _renderingType.isNotEmpty) {
                        String renderingType = _renderingType;
                        final link = _urlController.text;
                        if (_renderingType == RenderingTypeExtension.auto) {
                          final uri = Uri.tryParse(link);
                          if (uri != null) {
                            final res = await http
                                .head(uri)
                                .timeout(const Duration(milliseconds: 10000));
                            renderingType =
                                res.headers['content-type']?.toMimeType ??
                                    RenderingType.webview;
                          } else {
                            renderingType = RenderingType.webview;
                          }
                        }

                        Widget renderingWidget;
                        final previewURL = link;

                        switch (renderingType) {
                          case RenderingType.image:
                            renderingWidget = InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: ImageNFTRenderingWidget(
                                  previewURL: previewURL,
                                ),
                              ),
                            );
                          case RenderingType.video:
                            renderingWidget = InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: VideoNFTRenderingWidget(
                                  previewURL: previewURL,
                                ),
                              ),
                            );
                          case RenderingType.gif:
                            renderingWidget = InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: GifNFTRenderingWidget(
                                  previewURL: previewURL,
                                ),
                              ),
                            );
                          case RenderingType.svg:
                            renderingWidget = InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                  child: SVGNFTRenderingWidget(
                                      previewURL: previewURL)),
                            );
                          case RenderingType.pdf:
                            renderingWidget = Center(
                              child: PDFNFTRenderingWidget(
                                previewURL: previewURL,
                              ),
                            );
                          case RenderingType.audio:
                            renderingWidget = Center(
                              child: AudioNFTRenderingWidget(
                                previewURL: previewURL,
                              ),
                            );
                          default:
                            renderingWidget = Center(
                              child: WebviewNFTRenderingWidget(
                                previewURL: previewURL,
                              ),
                            );
                        }

                        setState(() {
                          _renderingWidget = renderingWidget;
                        });
                      }
                    },
                    text: 'test_artwork'.tr(),
                  ),
                  Visibility(
                    visible: _renderingWidget != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _renderingWidget,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

extension RenderingTypeExtension on RenderingType {
  static const String auto = 'auto';
}
