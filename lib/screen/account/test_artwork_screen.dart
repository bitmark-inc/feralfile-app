import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

bool testArtworkMode = false;
String? testArtworkRenderingType;
String? testArtworkPreviewURL;

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
                      final isInhouse = await isAppCenterBuild();
                      if (!isInhouse) {
                        return;
                      }
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

                          setState(() {
                            testArtworkMode = true;
                            testArtworkRenderingType = renderingType;
                            testArtworkPreviewURL = link;
                          });
                        }
                      }
                    },
                    text: 'test_artwork'.tr(),
                  ),
                  PrimaryButton(
                    enabled: testArtworkMode,
                    onTap: () {
                      setState(() {
                        testArtworkMode = false;
                        testArtworkRenderingType = null;
                        testArtworkPreviewURL = null;
                      });
                    },
                    text: 'Turn off test artwork mode',
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
