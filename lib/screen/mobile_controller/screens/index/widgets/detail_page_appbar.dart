import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

PreferredSize detailPageAppBar(BuildContext context, String title) {
  final theme = Theme.of(context);

  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight + 20),
    child: Container(
      color: AppColor.auGreyBackground,
      padding: const EdgeInsets.all(10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.auLightGrey),
                  borderRadius: BorderRadius.circular(90),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/arrow-left.svg',
                      width: 15,
                      height: 12,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      title,
                      style: theme.textTheme.ppMori400Grey12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            FFCastButton(
              displayKey: '',
              onDeviceSelected: (device) async {},
            ),
          ],
        ),
      ),
    ),
  );
}
