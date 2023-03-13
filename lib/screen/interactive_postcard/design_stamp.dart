import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DesignStampPage extends StatefulWidget {
  const DesignStampPage({Key? key}) : super(key: key);

  @override
  State<DesignStampPage> createState() => _DesignStampPageState();
}

class _DesignStampPageState extends State<DesignStampPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar: getBackAppBar(
        context,
        title: "stamp".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: ResponsiveLayout.padding),
        child: Column(
          children: [
            Text(
              "stamp_explain".tr(),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                text: "stamp_postcard".tr(),
                onTap: () {

                },
              ),
            ),
          ],
        )
      ),
    );
  }
}
