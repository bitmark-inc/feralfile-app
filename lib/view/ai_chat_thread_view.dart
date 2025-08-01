import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/view/ai_chat_view_widget.dart';
import 'package:autonomy_flutter/view/dp1_response_visual_view.dart';
import 'package:autonomy_flutter/view/keep_alive_widget.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class AiChatThreadView extends StatefulWidget {
  const AiChatThreadView({
    this.onMessage,
    super.key,
    this.initialMessages = const [],
  });

  final Future<void> Function(String message)? onMessage;
  final List<types.Message> initialMessages;

  @override
  State<AiChatThreadView> createState() => _AiChatThreadViewState();
}

class _AiChatThreadViewState extends State<AiChatThreadView>
    with RouteAware, WidgetsBindingObserver {
  late RecordBloc recordBloc;

  @override
  void initState() {
    recordBloc = context.read<RecordBloc>();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual Result Area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: AppColor.primaryBlack)),
                // background always fills
                const SizedBox.expand(child: DP1ResponseVisualView()),
              ],
            ),
          ), // Use DP1ResponseVisualView
          // Chat View Area
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: AppColor.auGreyBackground),
                ),
                SizedBox.expand(
                  child: KeepAliveWidget(
                    child: AiChatViewWidget(
                      onMessage: _onMessage,
                      initialMessages: widget.initialMessages,
                      messageLimit: null,
                    ),
                  ),
                ),
              ],
            ), // Use the new widget
          ),
          KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
            if (isKeyboardVisible) {
              return Container(
                padding: MediaQuery.of(context).viewInsets,
                child: SizedBox(
                  height: 8,
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: nowDisplayingShowing,
              builder: (context, value, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: MediaQuery.of(context).padding.bottom +
                      (value ? (kNowDisplayingHeight + 8) : 0),
                );
              },
            );
          })
        ],
      ),
    );
  }

  Future<void> _onMessage(String message) async {
    recordBloc.add(SubmitTextEvent(message));
  }
}
