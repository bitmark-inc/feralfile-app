import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class ExternalAppInfoView extends StatelessWidget {
  final Widget icon;
  final String appName;
  final String status;
  final Color? statusColor;
  final Widget? actionIcon;
  final Function()? onTap;

  const ExternalAppInfoView({
    Key? key,
    required this.icon,
    required this.appName,
    required this.status,
    this.statusColor,
    this.actionIcon,
    this.onTap,
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
          if (actionIcon != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: actionIcon,
            )
          ]
        ],
      ),
    );
  }
}
