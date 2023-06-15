import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ExternalAppInfoView extends StatelessWidget {
  final Widget icon;
  final String appName;
  final String status;
  final Color? statusColor;

  const ExternalAppInfoView({
    Key? key,
    required this.icon,
    required this.appName,
    required this.status,
    this.statusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColor.auLightGrey,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 36),
          Text(
            appName,
            style: theme.textTheme.ppMori400Black14,
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: statusColor ?? AppColor.auQuickSilver),
                borderRadius: BorderRadius.circular(32.0),
              ),
            ),
            onPressed: null,
            child: Center(
              child: Text(
                status,
                style: theme.textTheme.ppMori400Grey14
                    .copyWith(color: statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CloudState extends StatefulWidget {
  const CloudState({Key? key}) : super(key: key);

  @override
  State<CloudState> createState() => _CloudStateState();
}

class _CloudStateState extends State<CloudState> {
  @override
  Widget build(BuildContext context) {
    return _backupState();
  }

  Widget _backupState() {
    if (Platform.isAndroid) {
      return _backupStateAndroid();
    } else {
      return _backupStateIOS();
    }
  }

  Widget _backupStateAndroid() {
    return FutureBuilder(
        future:
            injector<AccountService>().isAndroidEndToEndEncryptionAvailable(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final isAndroidEndToEndEncryptionAvailable = snapshot.data as bool?;
            return Row(
              children: [
                Image.asset("assets/images/googleCloud.png"),
                const SizedBox(width: 10),
                _cloudState(isAndroidEndToEndEncryptionAvailable),
              ],
            );
          } else {
            return const SizedBox();
          }
        });
  }

  Widget _backupStateIOS() {
    return ValueListenableBuilder<bool>(
        valueListenable: injector<CloudService>().isAvailableNotifier,
        builder: (BuildContext context, bool isAvailable, Widget? child) {
          return Row(
            children: [
              Image.asset("assets/images/iCloudDrive.png"),
              const SizedBox(width: 10),
              _cloudState(isAvailable)
            ],
          );
        });
  }

  Widget _cloudState(bool? state) {
    final theme = Theme.of(context);
    return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: state != true ? AppColor.red : AppColor.auGrey),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          child: Text(
            state == true ? "turned_on".tr() : "turned_off".tr(),
            style: theme.textTheme.ppMori400Grey14
                .copyWith(color: state != true ? AppColor.red : null),
          ),
        ));
  }
}
