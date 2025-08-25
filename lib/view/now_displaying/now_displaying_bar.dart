import 'package:autonomy_flutter/model/now_displaying_object.dart';
import 'package:autonomy_flutter/screen/mobile_controller/extensions/dp1_call_ext.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/view/now_displaying/dp1_now_displaying_expanded_view.dart';
import 'package:autonomy_flutter/view/now_displaying/dragable_sheet_view.dart';
import 'package:autonomy_flutter/view/now_displaying/now_displaying_view.dart';
import 'package:flutter/material.dart';

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
          expandedBuilder:
              (BuildContext context, ScrollController scrollController) {
            final status = NowDisplayingManager().nowDisplayingStatus;
            List<DP1Item> items = [];
            int? selectedIndex;
            if (status is NowDisplayingSuccess) {
              final nowDisplaying = status.object;
              if (nowDisplaying is DP1NowDisplayingObject) {
                items = nowDisplaying.dp1Items;
                selectedIndex = nowDisplaying.index;
              }
            }
            final playlist = DP1CallExtension.fromItems(items: items);
            return DP1NowDisplayingExpandedView(
              playlist: playlist,
              selectedIndex: selectedIndex,
            );
          }),
    );
  }
}
