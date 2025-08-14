import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/now_displaying_object.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/expandable_now_displaying_view.dart';
import 'package:autonomy_flutter/view/now_displaying/base_now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class DP1NowDisplayingView extends StatelessWidget {
  const DP1NowDisplayingView(this.object, {super.key});

  final DP1NowDisplayingObject object;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetToken = object.assetToken;
    return ExpandableNowDisplayingView(
      headerBuilder: (onMoreTap, isExpanded) {
        return NowDisplayingView(
          thumbnailBuilder: (context) {
            if (assetToken != null) {
              return AspectRatio(
                aspectRatio: 1,
                child: tokenGalleryThumbnailWidget(
                  context,
                  CompactedAssetToken.fromAssetToken(assetToken),
                  65,
                  useHero: false,
                ),
              );
            }
            return AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColor.auLightGrey,
              ),
            );
          },
          titleBuilder: (context) {
            final title = assetToken?.title ?? '';
            return Text(
              title,
              style: theme.textTheme.ppMori400Black14,
              overflow: TextOverflow.ellipsis,
            );
          },
          customAction: [
            if (!isExpanded ||
                (injector<NavigationService>()
                        .currentRoute
                        ?.isRecordScreenShowing ??
                    false))
              ValueListenableBuilder(
                valueListenable: CustomRouteObserver.currentRoute,
                builder: (context, route, child) {
                  if (route?.isRecordScreenShowing ?? false) {
                    return const SizedBox.shrink();
                  }
                  return child!;
                },
                child: GestureDetector(
                  child: Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: AppColor.feralFileLightBlue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onTap: () {
                    injector<NavigationService>().popToRouteOrPush(
                      AppRouter.voiceCommandPage,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
