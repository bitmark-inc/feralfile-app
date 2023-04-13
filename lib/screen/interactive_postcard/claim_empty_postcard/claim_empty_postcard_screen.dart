import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/how_it_works_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'claim_empty_postcard_bloc.dart';
import 'claim_empty_postcard_state.dart';

class ClaimEmptyPostCardScreen extends StatefulWidget {
  final String id;
  const ClaimEmptyPostCardScreen({super.key, required this.id});

  @override
  State<ClaimEmptyPostCardScreen> createState() =>
      _ClaimEmptyPostCardScreenState();
}

class _ClaimEmptyPostCardScreenState extends State<ClaimEmptyPostCardScreen> {
  final bloc = injector.get<ClaimEmptyPostCardBloc>();
  @override
  void initState() {
    super.initState();
    bloc.add(GetTokenEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimEmptyPostCardBloc, ClaimEmptyPostCardState>(
        listener: (context, state) {
          if (state.isClaimed == true) {
            Navigator.of(context).popAndPushNamed(AppRouter.postcardStartedPage,
                arguments: state.assetToken!);
          }
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
              ),
            );
          }
        },
        bloc: bloc,
        builder: (context, state) {
          final artwork = state.assetToken;
          if (artwork == null) return Container();
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.colorScheme.primary,
            appBar: AppBar(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              toolbarHeight: 0,
            ),
            body: Container(
              padding: const EdgeInsets.fromLTRB(14, 28, 14, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overScroll) {
                        overScroll.disallowIndicator();
                        return false;
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap: true,
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          Container(
                            color: theme.auQuickSilver,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 60,
                                    horizontal: 15,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: artwork.getPreviewUrl() ?? '',
                                    placeholder: (context, url) => const Center(
                                      child: PreviewPlaceholder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artwork.title ?? '',
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                    Text(
                                      "by ${artwork.artistName}",
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                SvgPicture.asset(
                                  "assets/images/penrose_moma.svg",
                                  color: theme.colorScheme.secondary,
                                  width: 27,
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const HowItWorksView(isFinal: false),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      children: [
                        OutlineButton(
                          text: "cancel".tr(),
                          color: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: PrimaryButton(
                            text: "mint_postcard".tr(),
                            enabled: state.isClaiming != true,
                            isProcessing: state.isClaiming == true,
                            onTap: () {
                              bloc.add(AcceptGiftEvent());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
