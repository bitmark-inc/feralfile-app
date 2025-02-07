import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/touchpad.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class KeyboardControlPagePayload {
  final String subtitle;
  final String description;
  final List<BaseDevice> devices;

  KeyboardControlPagePayload(this.subtitle, this.description, this.devices);
}

class KeyboardControlPage extends StatefulWidget {
  final KeyboardControlPagePayload payload;

  const KeyboardControlPage({required this.payload, super.key});

  @override
  State<StatefulWidget> createState() => _KeyboardControlPageState();
}

class _KeyboardControlPageState extends State<KeyboardControlPage>
    with AfterLayoutMixin, WidgetsBindingObserver, RouteAware {
  final _focusNode = FocusNode();
  final _controller = KeyboardVisibilityController();
  late StreamSubscription? _keyboardSubscription;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _textController.dispose();
    unawaited(_keyboardSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  void didPushNext() {
    super.didPushNext();
    setState(() {
      _isExpanded = true;
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    showKeyboard();
    _keyboardSubscription = _controller.onChange.listen((bool isVisible) {
      if (!isVisible && !_isExpanded) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  void showKeyboard() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.auGreyBackground,
      resizeToAvoidBottomInset: false,
      appBar: getDarkEmptyAppBar(AppColor.auGreyBackground),
      body: KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isKeyboardVisible) {
            _scrollController.jumpTo(0);
          }
        });
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              Container(
                height: 1,
                child: TextField(
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
                    _textController.text = '';
                    final devices = widget.payload.devices;
                    await injector<CanvasClientServiceV2>()
                        .sendKeyBoard(devices, code.codeUnitAt(0));
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: AppColor.auGreyBackground,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Expanded(
                        child: TouchPad(
                          devices: widget.payload.devices,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
