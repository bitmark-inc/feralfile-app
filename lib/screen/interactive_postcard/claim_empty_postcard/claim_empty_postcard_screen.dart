import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'claim_empty_postcard_state.dart';
import 'claim_empty_postcard_bloc.dart';

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
            Navigator.pop(context);
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
                            height: 30,
                          ),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: theme.auSuperTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Text(
                                    'How it works',
                                    style: theme.textTheme.ppMori700Black14,
                                  ),
                                ),
                                RichText(
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    text: "Introducing the ",
                                    style: theme.textTheme.ppMori400Black14,
                                    children: [
                                      TextSpan(
                                        text: 'MoMA Postcard Project, ',
                                        style: theme.textTheme.ppMori400Black14
                                            .copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'a collaborative, creative experience. Just design, stamp and send!',
                                        style: theme.textTheme.ppMori400Black14,
                                      ),
                                      TextSpan(
                                        text:
                                            "\n\nYour objective is simple: send the postcard on a journey as far around the world as you can.",
                                        style: theme.textTheme.ppMori400Black14,
                                      ),
                                      TextSpan(
                                        text:
                                            "\n\nTap \"accept postcard\" to begin",
                                        style: theme.textTheme.ppMori400Black14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Text(
                            "accept_ownership_desc".tr(),
                            style: theme.primaryTextTheme.ppMori400White14,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          PrimaryButton(
                            text: "accept_ownership".tr(),
                            enabled: state.isClaiming != true,
                            isProcessing: state.isClaiming == true,
                            onTap: () {
                              bloc.add(AcceptGiftEvent());
                            },
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          RichText(
                            text: TextSpan(
                              text: "airdrop_accept_privacy_policy".tr(),
                              style: theme.textTheme.ppMori400Grey12,
                              children: [
                                TextSpan(
                                    text: "airdrop_privacy_policy".tr(),
                                    style: makeLinkStyle(
                                      theme.textTheme.ppMori400Grey12,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {}),
                                TextSpan(
                                  text: ".",
                                  style: theme.primaryTextTheme.bodyLarge
                                      ?.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          OutlineButton(
                            text: "decline".tr(),
                            color: theme.colorScheme.primary,
                            onTap: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
