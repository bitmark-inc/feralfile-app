import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_rendering/nft_rendering.dart';

class TestArtworkScreen extends StatefulWidget {
  const TestArtworkScreen({Key? key}) : super(key: key);

  @override
  State<TestArtworkScreen> createState() => _TestArtworkScreenState();
}

class _TestArtworkScreenState extends State<TestArtworkScreen> {
  final _renderingTypes = [
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
  String _renderingType = RenderingType.webview;
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
                        _renderingType = value ?? RenderingType.webview;
                      });
                    }),
                AuPrimaryButton(
                  onPressed: () {
                    if (_urlController.text.isNotEmpty &&
                        _renderingType.isNotEmpty) {
                      renderingWidget =
                          typesOfNFTRenderingWidget(_renderingType);

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
