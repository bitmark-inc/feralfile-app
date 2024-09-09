import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

class ExhibitionCard extends StatelessWidget {
  final Exhibition exhibition;
  static const _exhibitionInfoDivideWidth = 20.0;
  final double? size;

  const ExhibitionCard({required this.exhibition, super.key, this.size});

  Widget _exhibitionItem({
    required BuildContext context,
    required List<Exhibition> viewableExhibitions,
    required Exhibition exhibition,
    required bool isFeaturedExhibition,
  }) {
    final theme = Theme.of(context);
    final index = viewableExhibitions.indexOf(exhibition);
    final titleStyle = theme.textTheme.ppMori400White16;
    final subTitleStyle = theme.textTheme.ppMori400Grey12;
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
                        height: size,
                        placeholderBuilder: (context) => Container(
                          height: size,
                          width: size,
                          color: Colors.transparent,
                          child: const LoadingWidget(),
                        ),
                      )
                    : FFCacheNetworkImage(
                        imageUrl: exhibition.coverUrl,
                        height: size,
                        maxWidthDiskCache: size?.toInt(),
                        memCacheWidth: size?.toInt(),
                        memCacheHeight: size?.toInt(),
                        maxHeightDiskCache: size?.toInt(),
                        cacheManager: injector<CacheManager>(),
                        placeholder: (context, url) => Container(
                          height: size,
                          width: size,
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
                  child: GestureDetector(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exhibition.isSoloExhibition &&
                            exhibition.artists != null) ...[
                          RichText(
                            text: TextSpan(
                              style: subTitleStyle.copyWith(
                                  decorationColor: AppColor.disabledColor),
                              children: [
                                TextSpan(text: 'works_by'.tr()),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      if (exhibition.artists![0].slug != null) {
                                        await injector<NavigationService>()
                                            .openFeralFileArtistPage(
                                          exhibition.artists![0].slug!,
                                        );
                                      }
                                    },
                                  text: exhibition.artists![0].displayAlias,
                                  style: TextStyle(
                                    decoration:
                                        exhibition.artists![0].slug != null
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (exhibition.curator != null)
                          RichText(
                            text: TextSpan(
                              style: subTitleStyle.copyWith(
                                  decorationColor: AppColor.disabledColor),
                              children: [
                                TextSpan(text: 'curated_by'.tr()),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      if (exhibition.curator!.slug != null) {
                                        await injector<NavigationService>()
                                            .openFeralFileCuratorPage(
                                                exhibition.curator!.slug!);
                                      }
                                    },
                                  text: exhibition.curator!.displayAlias,
                                  style: TextStyle(
                                    decoration: exhibition.curator!.slug != null
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                  ),
                                ),
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
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _exhibitionItem(
        context: context,
        viewableExhibitions: [exhibition],
        exhibition: exhibition,
        isFeaturedExhibition: false,
      );

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
