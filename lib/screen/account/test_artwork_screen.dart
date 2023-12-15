import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nft_rendering/nft_rendering.dart';

class TestArtworkScreen extends StatefulWidget {
  const TestArtworkScreen({Key? key}) : super(key: key);

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
  INFTRenderingWidget? renderingWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        Navigator.pop(context);
      }, title: 'test_artwork'.tr()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                            child: Text(e.toString()),
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
                              res.headers["content-type"]?.toMimeType ??
                                  RenderingType.webview;
                        } else {
                          renderingType = RenderingType.webview;
                        }
                      }
                      renderingWidget =
                          typesOfNFTRenderingWidget(renderingType);

                      renderingWidget?.setRenderWidgetBuilder(
                        RenderingWidgetBuilder(
                          previewURL: _urlController.text,
                        ),
                      );
                      setState(() {});
                    }
                  },
                  text: 'test_artwork'.tr(),
                ),
                Visibility(
                  visible: renderingWidget != null,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: renderingToken(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget renderingToken() {
    switch (_renderingType) {
      case "image":
      case "svg":
      case 'gif':
      case "audio":
      case "video":
        return Stack(
          children: [
            AbsorbPointer(
              child: Center(
                child: IntrinsicHeight(
                  child: Container(child: renderingWidget?.build(context)),
                ),
              ),
            ),
          ],
        );

      default:
        return AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Center(
                child: Container(child: renderingWidget?.build(context)),
              ),
            ],
          ),
        );
    }
  }
}

extension RenderingTypeExtension on RenderingType {
  static const String auto = "auto";
}
