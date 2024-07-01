import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/ff_artwork_thumbnail_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class FeaturedWorksPage extends StatefulWidget {
  const FeaturedWorksPage({super.key});

  @override
  State<FeaturedWorksPage> createState() => _FeaturedWorksPageState();
}

class _FeaturedWorksPageState extends State<FeaturedWorksPage> {
  static const _padding = 14.0;
  static const _axisSpacing = 10.0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
          title: Text(
            'featured_works'.tr(),
          ),
        ),
        backgroundColor: AppColor.primaryBlack,
        body: _artworkSliverGrid(context),
      );

  Widget _artworkSliverGrid(BuildContext context) => Padding(
        padding:
            const EdgeInsets.only(left: _padding, right: _padding, bottom: 20),
        child: CustomScrollView(
          slivers: [
            FutureBuilder<List<Artwork>>(
              // ignore: discarded_futures
              future: injector<FeralFileService>().getFeaturedArtworks(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: loadingIndicator(valueColor: AppColor.auGrey)),
                    );
                  case ConnectionState.done:
                    if (snapshot.data == null || snapshot.data!.isEmpty) {
                      final theme = Theme.of(context);
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'featured_works_empty'.tr(),
                            style: theme.textTheme.ppMori400White14,
                          ),
                        ),
                      );
                    } else {
                      return SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: _axisSpacing,
                          mainAxisSpacing: _axisSpacing,
                          crossAxisCount: 3,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) => FFArtworkThumbnailView(
                          artwork: snapshot.data![index],
                          cacheSize: (MediaQuery.sizeOf(context).width -
                                  _padding * 2 -
                                  _axisSpacing * 2) ~/
                              3,
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              AppRouter.ffArtworkPreviewPage,
                              arguments: FeralFileArtworkPreviewPagePayload(
                                artwork: snapshot.data![index],
                              ),
                            );
                          },
                        ),
                      );
                    }
                  default:
                    return const SizedBox();
                }
              },
            ),
          ],
        ),
      );
}
