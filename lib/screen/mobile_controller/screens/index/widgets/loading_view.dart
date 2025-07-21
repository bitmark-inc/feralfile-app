import 'package:autonomy_flutter/view/loading.dart';
import 'package:feralfile_app_theme/style/colors.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingWidget(
        backgroundColor: AppColor.auGreyBackground,
      ),
    );
  }
}
