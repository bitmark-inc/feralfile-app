import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/now_displaying_object.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/extensions/dp1_call_ext.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/view/dp1_playlist_list_view.dart';
import 'package:autonomy_flutter/view/now_displaying/dragable_sheet_view.dart';
import 'package:autonomy_flutter/view/now_displaying/now_displaying_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NowDisplayingBar extends StatelessWidget {
  const NowDisplayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 363,
      child: TwoStopDraggableSheet(
          minSize: 57 / 363,
          maxSize: 1,
          collapsedBuilder: (context, scrollController) {
            return Column(
              children: [
                NowDisplaying(),
              ],
            );
          },
          expandedBuilder: (BuildContext context, ScrollController _) {
            final theme = Theme.of(context);
            final status = NowDisplayingManager().nowDisplayingStatus;
            List<DP1Item> items = [];
            int? selectedIndex;
            if (status is NowDisplayingSuccess) {
              final nowDisplaying = (status as NowDisplayingSuccess).object;
              if (nowDisplaying is DP1NowDisplayingObject) {
                items = nowDisplaying.dp1Items;
              }
              selectedIndex = (nowDisplaying as DP1NowDisplayingObject).index;
            }
            final playlist = DP1CallExtension.fromItems(items: items);
            return Container(
              color: AppColor.white,
              padding: EdgeInsets.fromLTRB(12, 30, 12, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('STUDIO',
                          style: theme.textTheme.ppMori400Black12
                              .copyWith(fontWeight: FontWeight.w700)),
                      Spacer(),
                      CustomPrimaryAsyncButton(
                        onTap: () {
                          injector<NavigationService>().navigateTo(
                            AppRouter.scanQRPage,
                            arguments: const ScanQRPagePayload(
                                scannerItem: ScannerItem.GLOBAL),
                          );
                        },
                        child: Container(
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/Add.svg',
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Add FF1',
                                style: theme.textTheme.ppMori400Black12,
                              ),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 11,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: PlaylistAssetListView(
                      playlist: playlist,
                      selectedIndex: selectedIndex,
                      scrollController: ScrollController(),
                      backgroundColor: AppColor.white,
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}
