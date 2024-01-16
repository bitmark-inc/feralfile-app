// ignore_for_file: discarded_futures, unawaited_futures

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/claim/activation/preview_activation_claim.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:marqueer/marqueer.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

class ClaimActivationPagePayload {
  final AssetToken assetToken;
  final String activationID;
  final Otp otp;

  ClaimActivationPagePayload({
    required this.assetToken,
    required this.activationID,
    required this.otp,
  });
}

class ClaimActivationPage extends StatefulWidget {
  final ClaimActivationPagePayload payload;

  const ClaimActivationPage({
    required this.payload,
    super.key,
  });

  @override
  State<ClaimActivationPage> createState() => _ClaimActivationPageState();
}

class _ClaimActivationPageState extends State<ClaimActivationPage> {
  bool _processing = false;

  final _metricClient = injector.get<MetricClientService>();
  final _accountService = injector<AccountService>();
  final _activationService = injector<ActivationService>();
  final _configService = injector<ConfigurationService>();

  @override
  Widget build(BuildContext context) {
    final assetToken = widget.payload.assetToken;
    final artistName = widget.payload.assetToken.artistName!;
    String gifter = 'Gitfer';
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
                                      imageUrl: assetToken.previewURL!,
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
                        onTap: () {},
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
                                    assetToken.title!,
                                    style: theme.textTheme.ppMori400White14,
                                    maxFontSize: 14,
                                    minFontSize: 14,
                                    maxLines: 2,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PreviewActivationTokenPage(
                                          assetToken: widget.payload.assetToken,
                                        ),
                                      ),
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
                        _metricClient.addEvent(
                          MixpanelEvent.acceptOwnership,
                          data: {
                            'id': widget.payload.assetToken.id,
                          },
                        );
                        setState(() {
                          _processing = true;
                        });
                        final blockchain = widget.payload.assetToken.blockchain;
                        final addresses =
                            await _accountService.getAddress(blockchain);

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
                          _metricClient.mixPanelClient.initIfDefaultAccount();
                          await _configService.setPendingSettings(true);
                          address = walletAddress.first.address;
                        } else if (addresses.length == 1) {
                          address = addresses.first;
                        } else {
                          if (mounted) {
                            final response =
                                await Navigator.of(context).pushNamed(
                              AppRouter.receivePostcardSelectAccountPage,
                              arguments: ReceivePostcardSelectAccountPageArgs(
                                blockchain,
                                withLinked: false,
                              ),
                            );
                            address = response as String?;
                          }
                        }

                        if (address != null && mounted) {
                          _claimActivation(
                            context: context,
                            activationID: widget.payload.activationID,
                            receiveAddress: address,
                            otp: widget.payload.otp,
                            assetToken: widget.payload.assetToken,
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
                _metricClient.addEvent(
                  MixpanelEvent.declineOwnership,
                  data: {
                    'id': widget.payload.assetToken.id,
                  },
                );
                memoryValues.branchDeeplinkData.value = null;
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _claimActivation(
      {required BuildContext context,
      required String activationID,
      required String receiveAddress,
      required AssetToken assetToken,
      required Otp otp}) async {
    try {
      await _activationService.claimActivation(
        request: ActivationClaimRequest(
          activationID: activationID,
          address: receiveAddress,
          airdropTOTPPasscode: otp.code,
        ),
        assetToken: assetToken,
      );
      _metricClient.addEvent(
        MixpanelEvent.acceptOwnershipSuccess,
        data: {
          'id': widget.payload.assetToken.id,
        },
      );
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      );
      NftCollectionBloc.eventController
          .add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
      final token = widget.payload.assetToken;
      const caption = '';
      Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
          arguments: ArtworkDetailPayload(
              [ArtworkIdentity(token.id, receiveAddress)], 0,
              twitterCaption: caption));
    }
  }
}
