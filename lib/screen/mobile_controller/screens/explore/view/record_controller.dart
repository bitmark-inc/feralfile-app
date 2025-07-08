import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    recordBloc =
        RecordBloc(mobileControllerService, audioService, configurationService);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocProvider.value(
      value: recordBloc,
      child: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
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
                      Builder(
                        builder: (context) {
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
                              return Center(
                                child: Text(
                                  (state.error as AudioException).message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .ppMori400Black14
                                      .copyWith(color: Colors.red),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
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
        },
      ),
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
          style: Theme.of(context).textTheme.ppMori400Black14,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _historyChat(BuildContext context) {
    var messages = configurationService.getRecordedMessages();
    if (messages.isEmpty) {
      messages = UIConstants.sampleHistoryAsks;
    }

    return ListView.builder(
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
                style: theme.textTheme.ppMori400Grey14,
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

  @override
  bool get wantKeepAlive => true;
}
