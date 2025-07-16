import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailPageAppBar(
      {super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.auGreyBackground,
      padding: const EdgeInsets.all(10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _backIcon(context, title)),
            const SizedBox(width: 10),
            ...actions.map(
              (e) => Row(
                children: [
                  e,
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backIcon(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.auLightGrey),
              borderRadius: BorderRadius.circular(90),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/arrow-left.svg',
                  width: 15,
                  height: 12,
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.ppMori400Grey12,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
