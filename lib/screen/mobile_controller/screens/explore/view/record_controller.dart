import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
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
  late RecordBloc recordBloc;

  @override
  void initState() {
    recordBloc = RecordBloc(mobileControllerService, audioService);
    // Permission.microphone.onGrantedCallback(
    //   () => recordBloc.add(StartRecordingEvent()),
    // );
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
                child: Padding(
                  padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      if (state is RecordProcessingState) ...[
                        Center(
                          child: Text(
                            state.processingMessage,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .ppMori400Grey14
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (state is RecordErrorState) ...[
                        if (state.error is AudioPermissionDeniedException)
                          _noPermissionWidget(context)
                        else if (state.error is AudioException) ...[
                          Center(
                            child: Text(
                              (state.error as AudioException).message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .ppMori400Black14
                                  .copyWith(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _historyChat(context, state.messages),
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
        duration: const Duration(milliseconds: 300),
        width: isRecording ? 260 : 220,
        height: isRecording ? 260 : 220,
        decoration: BoxDecoration(
          color:
              isRecording ? AppColor.feralFileLightBlue : AppColor.auLightGrey,
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
              ? 'RECORDING...'
              : isProcessing
                  ? 'PROCESSING...'
                  : 'ASK ME ANYTHING',
          style: Theme.of(context).textTheme.ppMori400Black14,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _historyChat(BuildContext context, List<String> messages) {
    messages = [
      'Hey FF1, find me a 2‑hour generative art mix that feels like Bauhaus colours.',
      'Show me work by Casey Rease.',
      'Hey FF1, find me a 2‑hour generative art mix that feels like Bauhaus colours.',
      'Hey FF1, find me a 2‑hour generative art mix that feels like Bauhaus colours.',
      'Show me work by Casey Rease.',
    ];
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
            if (index != 0) addDivider(color: AppColor.primaryBlack, height: 1),
            Padding(
              padding: ResponsiveLayout.paddingAll,
              child: Text(
                messages[index],
                style: theme.textTheme.ppMori400Grey14,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _noPermissionWidget(BuildContext context) {
    return Column(
      children: [
        Text(
          'Microphone permission is required.',
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
