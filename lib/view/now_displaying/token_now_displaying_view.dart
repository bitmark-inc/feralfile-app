import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/now_displaying/base_now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TokenNowDisplayingView extends StatelessWidget {
  TokenNowDisplayingView(this.assetToken, {super.key}) {
    _identityBloc.add(GetIdentityEvent([assetToken.artistTitle ?? '']));
  }

  final CompactedAssetToken assetToken;

  IdentityBloc get _identityBloc => injector<IdentityBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdentityBloc, IdentityState>(
      bloc: _identityBloc,
      builder: (context, state) {
        final artistTitle =
            assetToken.artistTitle?.toIdentityOrMask(state.identityMap) ??
                assetToken.artistTitle;
        return NowDisplayingView(
          thumbnailBuilder: thumbnailBuilder,
          titleBuilder: (context) => titleBuilder(context),
          artistBuilder: (context) => Text(
            artistTitle ?? '',
            style: Theme.of(context).textTheme.ppMori400Black14,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          customAction: [
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

  Widget titleBuilder(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        children: [
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
