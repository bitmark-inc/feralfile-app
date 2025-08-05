import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/ai_chat_thread_view.dart';
import 'package:autonomy_flutter/view/ai_chat_view_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

ValueNotifier<bool> chatModeNotifier = ValueNotifier<bool>(false);

class RecordControllerScreen extends StatefulWidget {
  const RecordControllerScreen({super.key});

  @override
  State<RecordControllerScreen> createState() => _RecordControllerScreenState();
}

class _RecordControllerScreenState extends State<RecordControllerScreen>
    with AutomaticKeepAliveClientMixin {
  final MobileControllerService mobileControllerService =
      injector<MobileControllerService>();
  final AudioService audioService = injector<AudioService>();
  final ConfigurationService configurationService =
      injector<ConfigurationService>();
  late RecordBloc recordBloc;

  @override
  void initState() {
    recordBloc = context.read<RecordBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return ValueListenableBuilder(
      valueListenable: chatModeNotifier,
      builder: (context, chatModeView, child) {
        return BlocProvider.value(
          value: recordBloc,
          child: BlocConsumer<RecordBloc, RecordState>(
            listener: (context, state) {
              if (state is RecordSuccessState) {
                chatModeNotifier.value = true;
              }
            },
            builder: (context, state) {
              return IndexedStack(index: chatModeView ? 0 : 1, children: [
                _aiChatThreadView(
                  context,
                  state is RecordSuccessState ? state : null,
                ),
                _recordView(context, state)
              ]);
            },
          ),
        );
      },
    );
  }

  Widget _recordView(BuildContext context, RecordState state) {
    return Column(
      children: [
        const SizedBox(
          height: UIConstants.topControlsBarHeight,
        ),
        Expanded(
          flex: 6,
          child: Center(
            child: Column(
              children: [
                // const SizedBox(height: 60),
                Center(
                  child: GestureDetector(
                    onTap: state is RecordProcessingState
                        ? null
                        : () {
                            context.read<RecordBloc>().add(
                                  state is RecordRecordingState
                                      ? StopRecordingEvent()
                                      : StartRecordingEvent(),
                                );
                          },
                    child: _askAnythingWidget(
                      context,
                      state,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          if (state is RecordSuccessState &&
                              state.lastDP1Call!.items.isEmpty) {
                            return _errorWidget(
                              context,
                              AudioException(state.response),
                            );
                          }
                          if (state is RecordProcessingState) {
                            return Center(
                              child: Text(
                                state.processingMessage,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .ppMori400Grey14
                                    .copyWith(color: Colors.white),
                              ),
                            );
                          } else if (state is RecordErrorState) {
                            if (state.error is AudioPermissionDeniedException) {
                              return _noPermissionWidget(context);
                            } else if (state.error is AudioException) {
                              return _errorWidget(
                                context,
                                state.error as AudioException,
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _historyChat(context),
        ),
      ],
    );
  }

  Widget _aiChatThreadView(BuildContext context, RecordSuccessState? state) {
    final messages = <types.Message>[];
    if (state != null) {
      final userMessage = types.TextMessage(
        author: aiChatUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: state.transcription,
      );
      final aiBotMessage = types.TextMessage(
        author: aiChatBot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: state.response,
      );
      messages.addAll([userMessage, aiBotMessage]);
    }

    return Column(
      children: [
        Container(
          color: AppColor.primaryBlack,
          height: UIConstants.topControlsBarHeight,
        ),
        AiChatThreadView(
          initialMessages: [],
        ),
      ],
    );
  }

  Widget _askAnythingWidget(BuildContext context, RecordState state) {
    final isRecording = state is RecordRecordingState;
    final isProcessing = state is RecordProcessingState;

    return ColoredBox(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: UIConstants.animationDuration,
        width: isRecording
            ? UIConstants.recordButtonSizeActive
            : UIConstants.recordButtonSize,
        height: isRecording
            ? UIConstants.recordButtonSizeActive
            : UIConstants.recordButtonSize,
        decoration: BoxDecoration(
          color: AppColor.feralFileLightBlue,
          shape: BoxShape.circle,
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          isRecording
              ? MessageConstants.recordingText
              : isProcessing
                  ? MessageConstants.processingText
                  : MessageConstants.askAnythingText,
          style: Theme.of(context).textTheme.ppMori400Black12,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _historyChat(BuildContext context) {
    var messages = configurationService.getRecordedMessages();
    if (kDebugMode && messages.isEmpty) {
      messages = UIConstants.sampleHistoryAsks;
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const SizedBox(height: 100);
        }

        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveLayout.paddingAll,
              child: Text(
                messages[index],
                style: theme.textTheme.ppMori400Grey12,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            addDivider(color: AppColor.primaryBlack, height: 1),
          ],
        );
      },
    );
  }

  Widget _noPermissionWidget(BuildContext context) {
    return Column(
      children: [
        Text(
          AudioExceptionType.permissionDenied.message,
          style: Theme.of(context).textTheme.ppMori400White12,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Request Permission',
          onTap: () async {
            await injector<NavigationService>().openMicrophoneSettings();
          },
        ),
      ],
    );
  }

  Widget _errorWidget(BuildContext context, AudioException error) {
    return Center(
      child: Text(
        error.message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.ppMori400White12,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
