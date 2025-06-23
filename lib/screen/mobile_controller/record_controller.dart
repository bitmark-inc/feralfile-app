import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/record_controller_bloc.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecordControllerScreen extends StatefulWidget {
  const RecordControllerScreen({super.key});

  @override
  State<RecordControllerScreen> createState() => _RecordControllerScreenState();
}

class _RecordControllerScreenState extends State<RecordControllerScreen> {
  final MobileControllerService mobileControllerService =
      injector<MobileControllerService>();
  final AudioService audioService = injector<AudioService>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecordBloc(mobileControllerService, audioService),
      // Start recording when screen is opened
      child: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColor.auGreyBackground,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Nút ghi âm
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () {
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
                            child: _askAnythingWidget(
                              context,
                              state.isRecording,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Danh sách message
                  _historyChat(context, state.messages),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _askAnythingWidget(BuildContext context, bool isRecording) {
    return Container(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isRecording ? 220 : 180,
        height: isRecording ? 220 : 180,
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
          isRecording ? 'RECORDING...' : 'ASK ME ANYTHING',
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
}
