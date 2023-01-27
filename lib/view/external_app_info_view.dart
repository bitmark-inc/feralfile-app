import 'package:autonomy_theme/autonomy_theme.dart';
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
          borderRadius: BorderRadiusGeometry.lerp(
              const BorderRadius.all(Radius.circular(5)),
              const BorderRadius.all(Radius.circular(5)),
              5)),
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
              backgroundColor: AppColor.auLightGrey,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: statusColor ?? AppColor.auQuickSilver),
                borderRadius: BorderRadius.circular(32.0),
              ),
            ),
            onPressed: null,
            child: Center(
              child: Text(
                status,
                style: theme.textTheme.ppMori400Black14
                    .copyWith(color: statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
