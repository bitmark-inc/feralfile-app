import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final double progress;

  const ProgressBar({required this.progress, super.key});

  @override
  State<ProgressBar> createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  late double _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        child: LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppColor.greyMedium,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColor.white),
        ),
      );
}
