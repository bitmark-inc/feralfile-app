import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:autonomy_flutter/view/ff_exhibition_participants.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

class ExhibitionCard extends StatelessWidget {
  final Exhibition exhibition;
  final List<Exhibition> viewableExhibitions;
  final double? horizontalMargin;
  final double? width;
  final double? height;
  static const _exhibitionInfoDivideWidth = 20.0;

  const ExhibitionCard({
    required this.exhibition,
    required this.viewableExhibitions,
    this.horizontalMargin,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final estimatedHeight =
        height ?? ((screenWidth - (horizontalMargin ?? 0) * 2) / 16 * 9);
    final estimatedWidth = width ?? (screenWidth - (horizontalMargin ?? 0) * 2);
    final index = viewableExhibitions.indexOf(exhibition);
    final titleStyle = theme.textTheme.ppMori400White16;
    final subTitleStyle = theme.textTheme.ppMori400Grey12;

    final listCurators =
        (exhibition.curator != null || exhibition.curators != null)
            ? exhibition.id == SOURCE_EXHIBITION_ID
                ? exhibition.curators!
                : [exhibition.curator!]
            : <AlumniAccount>[];

    return GestureDetector(
      onTap: () async => _onExhibitionTap(context, viewableExhibitions, index),
      behavior: HitTestBehavior.deferToChild,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 347 / 187,
                child: exhibition.id == SOURCE_EXHIBITION_ID
                    ? SvgPicture.network(
                        exhibition.coverUrl,
                        height: estimatedHeight,
                        placeholderBuilder: (context) => Container(
                          height: estimatedHeight,
                          width: estimatedWidth,
                          color: Colors.transparent,
                          child: const LoadingWidget(),
                        ),
                      )
                    : FFCacheNetworkImage(
                        imageUrl: exhibition.coverUrl,
                        height: estimatedHeight,
                        maxWidthDiskCache: estimatedWidth.toInt(),
                        memCacheWidth: estimatedWidth.toInt(),
                        memCacheHeight: estimatedHeight.toInt(),
                        maxHeightDiskCache: estimatedHeight.toInt(),
                        cacheManager: injector<CacheManager>(),
                        placeholder: (context, url) => Container(
                          height: estimatedHeight,
                          width: estimatedWidth,
                          color: Colors.transparent,
                          child: const LoadingWidget(),
                        ),
                        fit: BoxFit.fitWidth,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AutoSizeText(
                    exhibition.title,
                    style: titleStyle,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: _exhibitionInfoDivideWidth),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exhibition.isSoloExhibition &&
                          exhibition.artists != null) ...[
                        RichText(
                          textScaler: MediaQuery.textScalerOf(context),
                          text: TextSpan(
                            style: subTitleStyle.copyWith(
                                decorationColor: AppColor.disabledColor),
                            children: [
                              TextSpan(text: 'works_by'.tr()),
                              ...exhibitionParticipantSpans(
                                  [exhibition.artists![0]]),
                            ],
                          ),
                        ),
                      ],
                      if (listCurators.isNotEmpty)
                        RichText(
                          textScaler: MediaQuery.textScalerOf(context),
                          text: TextSpan(
                            style: subTitleStyle.copyWith(
                                decorationColor: AppColor.disabledColor),
                            children: [
                              TextSpan(text: 'curated_by'.tr()),
                              ...exhibitionParticipantSpans(listCurators),
                            ],
                          ),
                        ),
                      Text(
                        exhibition.isGroupExhibition
                            ? 'group_exhibition'.tr()
                            : 'solo_exhibition'.tr(),
                        style: subTitleStyle,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onExhibitionTap(BuildContext context,
      List<Exhibition> viewableExhibitions, int index) async {
    if (index >= 0) {
      await Navigator.of(context).pushNamed(
        AppRouter.exhibitionDetailPage,
        arguments: ExhibitionDetailPayload(
          exhibitions: viewableExhibitions,
          index: index,
        ),
      );
    }
  }
}
