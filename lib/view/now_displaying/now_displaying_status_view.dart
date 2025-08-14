import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/view/expandable_now_displaying_view.dart';
import 'package:autonomy_flutter/view/now_displaying/custom_now_displaying_view.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NowDisplayingStatusView extends StatelessWidget {
  const NowDisplayingStatusView({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return ExpandableNowDisplayingView(
      headerBuilder: (onMoreTap, isExpanded) {
        return CustomNowDisplayingView(
          builder: (context) {
            return Container(
              constraints: const BoxConstraints(
                maxHeight: kNowDisplayingHeight,
                minHeight: kNowDisplayingHeight,
              ),
              child: Column(
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.ppMori400Black14,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
          customAction: [
            if (!isExpanded)
              ValueListenableBuilder(
                valueListenable: CustomRouteObserver.currentRoute,
                builder: (context, route, child) {
                  if (route?.isRecordScreenShowing ?? false) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: AppColor.feralFileLightBlue,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/voice_command.svg',
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    onTap: () {
                      injector<NavigationService>().popToRouteOrPush(
                        AppRouter.voiceCommandPage,
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
