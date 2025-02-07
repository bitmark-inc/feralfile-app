import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

class NowDisplayingView extends StatelessWidget {
  const NowDisplayingView(this.assetToken, {super.key});

  final CompactedAssetToken assetToken;

  IdentityBloc get _identityBloc => injector<IdentityBloc>();

  @override
  Widget build(BuildContext context) {
    _identityBloc.add(GetIdentityEvent([assetToken.artistTitle ?? '']));
    final theme = Theme.of(context);
    return BlocBuilder<IdentityBloc, IdentityState>(
      bloc: _identityBloc,
      builder: (context, state) {
        final artistTitle =
            assetToken.artistTitle?.toIdentityOrMask(state.identityMap) ??
                assetToken.artistTitle;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.feralFileLightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 65,
                  child: tokenGalleryThumbnailWidget(context, assetToken, 65)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Now Displaying:',
                      style: theme.textTheme.ppMori400Black14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (artistTitle != null) ...[
                          GestureDetector(
                            onTap: () {
                              if (assetToken.isFeralfile) {
                                injector<NavigationService>()
                                    .openFeralFileArtistPage(
                                  assetToken.artistID!,
                                );
                              } else {
                                final uri = Uri.parse(
                                  assetToken.artistURL
                                          ?.split(' & ')
                                          .firstOrNull ??
                                      '',
                                );
                                injector<NavigationService>().openUrl(uri);
                              }
                            },
                            child: Text(
                              artistTitle,
                              style: theme.textTheme.ppMori400Black14.copyWith(
                                decoration: TextDecoration.underline,
                                decorationColor: AppColor.primaryBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                        ],
                        if (assetToken.title != null)
                          Expanded(
                            child: Text(
                              assetToken.title!,
                              style: theme.textTheme.ppMori400Black14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
