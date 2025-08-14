import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/expandable_now_displaying_view.dart';
import 'package:autonomy_flutter/view/now_displaying/base_now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TokenNowDisplayingView extends StatelessWidget {
  const TokenNowDisplayingView(this.assetToken, {super.key});

  final CompactedAssetToken assetToken;

  IdentityBloc get _identityBloc => injector<IdentityBloc>();

  @override
  Widget build(BuildContext context) {
    _identityBloc.add(GetIdentityEvent([assetToken.artistTitle ?? '']));
    return BlocBuilder<IdentityBloc, IdentityState>(
      bloc: _identityBloc,
      builder: (context, state) {
        final artistTitle =
            assetToken.artistTitle?.toIdentityOrMask(state.identityMap) ??
                assetToken.artistTitle;
        return ExpandableNowDisplayingView(
          headerBuilder: (onMoreTap, isExpanded) {
            return NowDisplayingView(
              thumbnailBuilder: thumbnailBuilder,
              titleBuilder: (context) => titleBuilder(context, artistTitle),
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
                        ),
                        onTap: () {
                          injector<NavigationService>().popToRouteOrPush(
                            AppRouter.voiceCommandPage,
                          );
                        },
                      );
                    },
                  ),
              ], // Pass the dynamic icon here
            );
          },
        );
      },
    );
  }

  Widget thumbnailBuilder(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: tokenGalleryThumbnailWidget(
        context,
        assetToken,
        65,
        useHero: false,
      ),
    );
  }

  Widget titleBuilder(BuildContext context, String? artistTitle) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        children: [
          if (artistTitle != null)
            TextSpan(
              text: artistTitle,
              style: theme.textTheme.ppMori400Black14.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColor.primaryBlack,
              ),
            ),
          if (artistTitle != null)
            TextSpan(
              text: ', ',
              style: theme.textTheme.ppMori400Black14,
            ),
          TextSpan(
            text: assetToken.displayTitle,
            style: theme.textTheme.ppMori400Black14,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
