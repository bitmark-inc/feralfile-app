import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ClaimTokenPage extends StatefulWidget {
  final Exhibition exhibition;

  const ClaimTokenPage({
    Key? key,
    required this.exhibition,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ClaimTokenPageState();
  }
}

class _ClaimTokenPageState extends State<ClaimTokenPage> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final artwork = widget.exhibition.artworks.firstOrNull;
    final artist = widget.exhibition.getArtist(artwork);
    final artistName =
        artist?.fullName.isNotEmpty == true ? artist?.fullName : artist?.alias;
    final artworkThumbnail =
        artwork?.getThumbnailURL() ?? widget.exhibition.getThumbnailURL();
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Container(
        padding: EdgeInsets.fromLTRB(14, safeAreaTop + 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 52,
            ),
            Text(
              "congratulations".tr(),
              style: theme.primaryTextTheme.headline1,
            ),
            const SizedBox(
              height: 40,
            ),
            RichText(
              text: TextSpan(
                text: "you_can_receive_free_gift_from".tr(),
                style: theme.primaryTextTheme.bodyText1,
                children: [
                  TextSpan(
                    text: "MoMA",
                    style: theme.primaryTextTheme.bodyText1
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ".",
                    style: theme.primaryTextTheme.bodyText1,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Transform.translate(
                    offset: const Offset(1, 0),
                    child: ClipPath(
                      clipper: AutonomyTopRightRectangleClipper(),
                      child: CachedNetworkImage(
                        fit: BoxFit.fitWidth,
                        imageUrl: artworkThumbnail,
                        width: 264,
                        height: 264,
                      ),
                    ),
                  ),
                  Image.asset("assets/images/ribbon.png"),
                ],
              ),
              onTap: () {
                // TODO: open preview page.
              },
            ),
            const SizedBox(
              height: 24,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Text(
                artwork?.title ?? widget.exhibition.title,
                style: makeLinkStyle(theme.primaryTextTheme.bodyText1!.copyWith(
                  fontWeight: FontWeight.w700,
                )),
              ),
              onTap: () {
                // TODO: open preview
              },
            ),
            Text(
              "by $artistName",
              style: theme.primaryTextTheme.bodyText1,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "accept_ownership_desc".tr(),
              style: theme.primaryTextTheme.bodyText1,
            ),
            const SizedBox(
              height: 16,
            ),
            RichText(
              text: TextSpan(
                text: "airdrop_accept_privacy_policy".tr(),
                style: theme.primaryTextTheme.bodyText1?.copyWith(fontSize: 12),
                children: [
                  TextSpan(
                      text: "airdrop_privacy_policy".tr(),
                      style: makeLinkStyle(theme.primaryTextTheme.bodyText1!
                          .copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _openPrivacyPolicy();
                        }),
                  TextSpan(
                    text: ".",
                    style: theme.primaryTextTheme.bodyText1
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            AuFilledButton(
              text: "accept_ownership".tr(),
              color: theme.colorScheme.secondary,
              textStyle: theme.textTheme.button,
              enabled: !_processing,
              isProcessing: _processing,
              onPress: () async {
                setState(() {
                  _processing = true;
                });
                final blockchain =
                    widget.exhibition.mintBlockchain.capitalize();
                final accountService = injector<AccountService>();
                final addresses = await accountService.getAllAddresses();

                String? address;
                if (addresses.isEmpty) {
                  final defaultAccount = await accountService.getDefaultAccount();
                  await injector<ConfigurationService>().setDoneOnboarding(true);
                  address = blockchain == "Tezos"
                      ? (await defaultAccount.getTezosWallet()).address
                      : await defaultAccount.getETHAddress();
                } else {
                  if (!mounted) return;
                  final account = await Navigator.of(context).pushNamed(
                    AppRouter.claimSelectAccountPage,
                    arguments: blockchain,
                  ) as Account?;
                  final wallet = account?.persona?.wallet();
                  if (wallet != null) {
                    address = blockchain == "Tezos"
                        ? (await wallet.getTezosWallet()).address
                        : await wallet.getETHAddress();
                  } else if (account?.connections?.isNotEmpty == true) {
                    final connectionType = blockchain == "Tezos"
                        ? "walletBeacon"
                        : "walletConnect";
                    address = account?.connections
                        ?.firstWhereOrNull(
                            (e) => e.connectionType == connectionType)
                        ?.accountNumber;
                  }
                  address ??= account?.accountNumber;
                }
                if (address != null && mounted) {
                  _claimToken(context, address);
                } else {
                  setState(() {
                    _processing = false;
                  });
                }
              },
            ),
            AuFilledButton(
              text: "decline".tr(),
              enabled: !_processing,
              onPress: () {
                memoryValues.airdropFFExhibitionId = null;
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _claimToken(BuildContext context, String receiveAddress) async {
    final ffService = injector<FeralFileService>();
    try {
      await ffService.claimToken(
        exhibitionId: widget.exhibition.id,
        address: receiveAddress,
      );
      memoryValues.airdropFFExhibitionId = null;
    } catch (e) {
      log.info("[ClaimTokenPage] Claim token failed. $e");
      if (e is AirdropExpired) {
        await UIHelper.showAirdropExpired(context);
      } else if (e is DioError) {
        final ffError = e.error as FeralfileError?;
        final message = ffError != null
            ? "[${ffError.code}] ${ffError.message}"
            : "${e.response?.data ?? e.message}";
        await showErrorDialog(
          context,
          "error".tr(),
          message,
          "close".tr(),
        );
      }
    }
    setState(() {
      _processing = false;
    });
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
            (route) => false,
      );
    }
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).pushNamed(AppRouter.githubDocPage, arguments: {
      "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
      "document": "privacy.md",
      "title": ""
    });
  }
}
