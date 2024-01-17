import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExhibitionDetailLastPage extends StatelessWidget {
  const ExhibitionDetailLastPage(
      {required this.startOver, super.key, this.nextPayload});

  final Function() startOver;
  final ExhibitionDetailPayload? nextPayload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColor.auGreyBackground,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: startOver,
                        child: Text(
                          'start_over'.tr(),
                          style: theme.textTheme.ppMori400White14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/images/start_over.svg',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (nextPayload != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'next_exhibition'.tr(),
                  style: theme.textTheme.ppMori400White14,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).popAndPushNamed(
                      AppRouter.exhibitionDetailPage,
                      arguments: nextPayload,
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      nextPayload!.exhibitions[nextPayload!.index].coverUrl,
                      height: 140,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }
}
