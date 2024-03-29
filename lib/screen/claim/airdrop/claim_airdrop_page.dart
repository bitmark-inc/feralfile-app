import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/screen/claim/select_account_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marqueer/marqueer.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimAirdropPagePayload {
  final String claimID;
  final String shareCode;
  final FFSeries series;
  final bool allowViewOnlyClaim;

  ClaimAirdropPagePayload({
    required this.claimID,
    required this.shareCode,
    required this.series,
    this.allowViewOnlyClaim = false,
  });
}

class ClaimAirdropPage extends StatefulWidget {
  final ClaimAirdropPagePayload payload;

  const ClaimAirdropPage({
    required this.payload,
    super.key,
  });

  @override
  State<ClaimAirdropPage> createState() => _ClaimAirdropPageState();
}

class _ClaimAirdropPageState extends State<ClaimAirdropPage> {
  bool _processing = false;

  final _metricClient = injector.get<MetricClientService>();
  final _airdropService = injector<AirdropService>();
  final _accountService = injector<AccountService>();
  final _configService = injector<ConfigurationService>();

  @override
  Widget build(BuildContext context) {
    final artwork = widget.payload.series;
    final artist = artwork.artist;
    final artistName = artist != null ? artist.getDisplayName() : '';
    final artworkThumbnail = artwork.getThumbnailURL();
    String gifter =
        artwork.airdropInfo?.gifter?.replaceAll(' ', '\u00A0') ?? '';
    String giftIntro = 'you_can_receive_free_gift'.tr();
    if (gifter.trim().isNotEmpty) {
      giftIntro += " ${'from'.tr().toLowerCase()} ";
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Container(
        padding: const EdgeInsets.fromLTRB(14, 28, 14, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
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
                    FittedBox(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Transform.translate(
                          offset: const Offset(1, 0),
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 20,
                                  child: Marqueer(
                                    direction: MarqueerDirection.ltr,
                                    pps: 30,
                                    child: Text(
                                      'gift_edition'.tr(),
                                      style: theme.textTheme.ppMori400Black14,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 45,
                                    horizontal: 75,
                                  ),
                                  child: Container(
                                    color: Colors.black,
                                    child: CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      imageUrl: artworkThumbnail,
                                      width: 225,
                                      height: 225,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 30,
                                  child: Marqueer(
                                    pps: 30,
                                    child: Text(
                                      'gift_edition'.tr().toUpperCase(),
                                      style: theme.textTheme.ppMori400Black14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRouter.autonomyAirdropTokenPreviewPage,
                            arguments: widget.payload.series,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: AutoSizeText(
                                    artwork.title,
                                    style: theme.textTheme.ppMori400White14,
                                    maxFontSize: 14,
                                    minFontSize: 14,
                                    maxLines: 2,
                                  ),
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.autonomyAirdropTokenPreviewPage,
                                      arguments: widget.payload.series,
                                    );
                                  },
                                ),
                                Text(
                                  'by'.tr(args: [artistName]),
                                  style: theme.textTheme.ppMori400White14,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          SvgPicture.asset(
                            'assets/images/penrose_moma.svg',
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.secondary, BlendMode.srcIn),
                            height: 27,
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
                    RichText(
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: giftIntro,
                        style: theme.textTheme.ppMori400White14,
                        children: [
                          TextSpan(
                            text: gifter,
                            style: theme.primaryTextTheme.ppMori700White14,
                          ),
                          TextSpan(
                            text: '.',
                            style: theme.primaryTextTheme.ppMori400White14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    PrimaryButton(
                      text: 'accept_ownership'.tr(),
                      enabled: !_processing,
                      isProcessing: _processing,
                      onTap: () async {
                        setState(() {
                          _processing = true;
                        });
                        final blockchain = widget
                                .payload.series.exhibition?.mintBlockchain
                                .capitalize() ??
                            'Tezos';
                        final addresses = await _accountService.getAddress(
                            blockchain,
                            withViewOnly: widget.payload.allowViewOnlyClaim);

                        String? address;
                        if (addresses.isEmpty) {
                          final defaultPersona =
                              await _accountService.getOrCreateDefaultPersona();
                          final walletAddress =
                              await defaultPersona.insertNextAddress(
                                  blockchain.toLowerCase() == 'tezos'
                                      ? WalletType.Tezos
                                      : WalletType.Ethereum);
                          await _configService.setDoneOnboarding(true);
                          unawaited(_metricClient.mixPanelClient
                              .initIfDefaultAccount());
                          await _configService.setPendingSettings(true);
                          address = walletAddress.first.address;
                        } else if (addresses.length == 1) {
                          address = addresses.first;
                        } else {
                          if (mounted) {
                            final response =
                                await Navigator.of(context).pushNamed(
                              AppRouter.claimSelectAccountPage,
                              arguments: SelectAddressPagePayload(
                                blockchain: blockchain,
                                withViewOnly: true,
                              ),
                            );
                            address = response as String?;
                          }
                        }

                        if (address != null && mounted) {
                          await _claimToken(
                            context: context,
                            claimID: widget.payload.claimID,
                            shareCode: widget.payload.shareCode,
                            seriesId: widget.payload.series.id,
                            receiveAddress: address,
                          );
                        } else {
                          setState(() {
                            _processing = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text(
                      'accept_ownership_desc'.tr(),
                      style: theme.primaryTextTheme.ppMori400White14,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    RichText(
                      text: TextSpan(
                        text: 'airdrop_accept_privacy_policy'.tr(),
                        style: theme.textTheme.ppMori400Grey12,
                        children: [
                          TextSpan(
                              text: 'airdrop_privacy_policy'.tr(),
                              style: makeLinkStyle(
                                theme.textTheme.ppMori400Grey12,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _openFFArtistCollector();
                                }),
                          TextSpan(
                            text: '.',
                            style: theme.primaryTextTheme.bodyLarge
                                ?.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            OutlineButton(
              text: 'decline'.tr(),
              enabled: !_processing,
              color: theme.colorScheme.primary,
              onTap: () {
                memoryValues.branchDeeplinkData.value = null;
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _claimToken(
      {required BuildContext context,
      required String claimID,
      required String shareCode,
      required String seriesId,
      required String receiveAddress}) async {
    ClaimResponse? claimRespone;
    try {
      claimRespone = await _airdropService.claimGift(
          claimID: claimID,
          shareCode: shareCode,
          seriesId: seriesId,
          receivingAddress: receiveAddress);
      unawaited(_configService.setAlreadyClaimedAirdrop(seriesId, true));
    } catch (e) {
      setState(() {
        _processing = false;
      });
      return;
    }
    setState(() {
      _processing = false;
    });
    if (mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      );
      NftCollectionBloc.eventController
          .add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
      final token = claimRespone.token;
      final caption = claimRespone.airdropInfo.twitterCaption;
      if (mounted) {
        await Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
            arguments: ArtworkDetailPayload(
                [ArtworkIdentity(token.id, token.owner)], 0,
                twitterCaption: caption ?? ''));
      }
    }
  }

  void _openFFArtistCollector() {
    String uri = (widget.payload.series.exhibition?.id == null)
        ? FF_ARTIST_COLLECTOR
        : '$FF_ARTIST_COLLECTOR/${widget.payload.series.exhibition?.id}';
    unawaited(launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication));
  }
}
