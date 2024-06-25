import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/view/additional_info.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ExhibitionAdditionalInfoPage extends StatelessWidget {
  const ExhibitionAdditionalInfoPage({required this.info, super.key});

  final AdditionalInfo info;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
        ),
        backgroundColor: AppColor.primaryBlack,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: SingleChildScrollView(
            child: ExhibitionAdditionalInfo(
              info: info,
              isFull: true,
            ),
          ),
        ),
      );
}
