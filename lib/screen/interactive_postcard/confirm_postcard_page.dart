import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/jumping_dot.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfirmingPostcardPage extends StatefulWidget {
  final StampPreviewPayload payload;

  const ConfirmingPostcardPage({super.key, required this.payload});

  @override
  State<ConfirmingPostcardPage> createState() => _ConfirmingPostcardState();
}

class _ConfirmingPostcardState extends State<ConfirmingPostcardPage> {
  final _navigationService = injector<NavigationService>();
  final _configurationService = injector<ConfigurationService>();

  late Timer? timer;

  @override
  void initState() {
    const duration = Duration(seconds: 10);
    timer = Timer.periodic(duration, (timer) {
      if (mounted) {
        _refreshPostcard();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _refreshPostcard() {
    log.info("Refresh postcard");
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
          ArtworkIdentity(widget.payload.asset.id, widget.payload.asset.owner),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.primaryBlack,
        appBar: getBackAppBar(context,
            title: "preview_postcard".tr(), onBack: null, isWhite: false),
        body: BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
          listener: (context, state) {
            if (!(state.isPostcardUpdatingOnBlockchain ||
                state.isPostcardUpdating)) {
              if (state.assetToken == null) {
                return;
              }
              _navigationService.popUntilHomeOrSettings();
              if (!mounted) return;
              Navigator.of(context).pushNamed(
                AppRouter.claimedPostcardDetailsPage,
                arguments:
                    ArtworkDetailPayload([state.assetToken!.identity], 0),
              );
              _configurationService.setAutoShowPostcard(true);
            }
          },
          builder: (context, state) {
            final assetToken = widget.payload.asset;
            final imagePath = widget.payload.imagePath;
            final metadataPath = widget.payload.metadataPath;
            return Padding(
              padding: ResponsiveLayout.pageEdgeInsets,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PostcardRatio(
                    assetToken: assetToken,
                    imagePath: imagePath,
                    jsonPath: metadataPath,
                  ),
                  _action(state),
                ],
              ),
            );
          },
        ));
  }

  Widget _action(PostcardDetailState state) {
    final theme = Theme.of(context);
    if (state.isPostcardUpdatingOnBlockchain) {
      return PostcardCustomButton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "confirming_on_blockchain".tr(),
              style: theme.textTheme.moMASans700Black14,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: CustomJumpingDots(
                dotBuilder: (bool isActive) {
                  return Container(
                    width: 3,
                    height: 3,
                    color: isActive ? Colors.black : Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    if (state.isPostcardUpdating) {
      return PostcardCustomButton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "updating_token".tr(),
              style: theme.textTheme.moMASans700Black14,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: CustomJumpingDots(
                dotBuilder: (bool isActive) {
                  return Container(
                    width: 3,
                    height: 3,
                    color: isActive ? Colors.black : Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }
}
