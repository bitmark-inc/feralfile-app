import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_tv_proto/autonomy_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';

class KeyboardControlPagePayload {
  final AssetToken assetToken;
  final CanvasDevice device;

  KeyboardControlPagePayload(this.assetToken, this.device);
}

class KeyboardControlPage extends StatefulWidget {
  final KeyboardControlPagePayload payload;

  const KeyboardControlPage({super.key, required this.payload});

  @override
  State<StatefulWidget> createState() => _KeyboardControlPageState();
}

class _KeyboardControlPageState extends State<KeyboardControlPage>
    with AfterLayoutMixin, WidgetsBindingObserver {
  final _focusNode = FocusNode();
  final _controller = KeyboardVisibilityController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Navigator.of(context).pop();
      }
    });
    _textController.addListener(() {
      print("Helo");
    });
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    _textController.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    showKeyboard();
  }

  @override
  void didChangeMetrics() {
    print("");
    super.didChangeMetrics();
  }

  void showKeyboard() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetToken = widget.payload.assetToken;
    final editionSubTitle = getEditionSubTitle(assetToken);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Column(
            children: [
              addTitleSpace(),
              Visibility(
                visible: editionSubTitle.isNotEmpty,
                child: Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Text(
                    editionSubTitle,
                    style: theme.textTheme.ppMori400Grey14,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              HtmlWidget(
                customStylesBuilder: auHtmlStyle,
                assetToken.description ?? "",
                textStyle: theme.textTheme.ppMori400White14,
              ),
              HtmlWidget(
                customStylesBuilder: auHtmlStyle,
                assetToken.description ?? "",
                textStyle: theme.textTheme.ppMori400White14,
              ),
              HtmlWidget(
                customStylesBuilder: auHtmlStyle,
                assetToken.description ?? "",
                textStyle: theme.textTheme.ppMori400White14,
              ),
              HtmlWidget(
                customStylesBuilder: auHtmlStyle,
                assetToken.description ?? "",
                textStyle: theme.textTheme.ppMori400White14,
              ),
              TextField(
                focusNode: _focusNode,
                controller: _textController,
                autofocus: true,
                cursorColor: Colors.transparent,
                showCursor: false,
                autocorrect: false,
                enableSuggestions: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (_) async {
                  final text = _textController.text;
                  final code = text[text.length - 1];
                  _textController.text = "";
                  final device = widget.payload.device;
                  await injector<CanvasClientService>()
                      .sendKeyBoard(device, 10);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
