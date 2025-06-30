import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/record_controller_bloc.dart';
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
      // Start recording when screen is opened
      child: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, state) {
          final error = state.error;
          return Scaffold(
            backgroundColor: AppColor.auGreyBackground,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Nút ghi âm
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: state.isProcessing
                                  ? null
                                  : () {
                                      if (!state.isRecording) {
                                        context
                                            .read<RecordBloc>()
                                            .add(StartRecordingEvent());
                                      } else {
                                        context
                                            .read<RecordBloc>()
                                            .add(StopRecordingEvent());
                                      }
                                    },
                              child: _askAnythingWidget(context,
                                  state.isRecording, state.isProcessing),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (state.error == null &&
                              state.status != null &&
                              state.status!.isNotEmpty) ...[
                            Center(
                              child: Text(
                                state.status ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .ppMori400Grey14
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (error != null)
                            if (error is AudioPermissionDeniedException)
                              _noPermissionWidget(context)
                            else if (error is AudioException) ...[
                              Center(
                                child: Text(
                                  error.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .ppMori400Black14
                                      .copyWith(color: Colors.red),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _historyChat(context, state.messages),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _askAnythingWidget(
      BuildContext context, bool isRecording, bool isProcessing) {
    return Container(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isRecording ? 220 : 180,
        height: isRecording ? 220 : 180,
        decoration: BoxDecoration(
          color: !isProcessing
              ? AppColor.feralFileLightBlue
              : AppColor.auLightGrey,
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
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _historyChat(BuildContext context, List<String> messages) {
    return Expanded(
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  messages[index],
                  style: theme.textTheme.ppMori400Grey14,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              addDivider(color: AppColor.primaryBlack),
            ],
          );
        },
      ),
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
