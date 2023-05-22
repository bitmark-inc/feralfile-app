import 'dart:async';

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _textController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    showKeyboard();
    _controller.onChange.listen((bool isVisible) {
      if (!isVisible) {
        Navigator.of(context).pop();
      }
    });
    bool scrolledToTop = false;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_scrollController.offset != 0) {
        if (scrolledToTop) {
          _scrollController.jumpTo(0);
          timer.cancel();
        } else {
          scrolledToTop = true;
        }
      }
    });
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
      backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          controller: _scrollController,
          child: Padding(
            padding: ResponsiveLayout.getPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                addTitleSpace(),
                const SizedBox(
                  height: 30,
                ),
                Visibility(
                  visible: editionSubTitle.isNotEmpty,
                  child: Text(
                    editionSubTitle,
                    style: theme.textTheme.ppMori400Grey14,
                  ),
                ),
                const SizedBox(height: 16.0),
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
                        .sendKeyBoard(device, code.codeUnitAt(0));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
