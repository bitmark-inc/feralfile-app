import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/share_helper.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/dot_loading_indicator.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class StampPreview extends StatefulWidget {
  static const String tag = "stamp_preview";
  final StampPreviewPayload payload;
  static const double cellSize = 20.0;

  const StampPreview({Key? key, required this.payload}) : super(key: key);

  @override
  State<StampPreview> createState() => _StampPreviewState();
}

class _StampPreviewState extends State<StampPreview> {
  Uint8List? postcardData;
  Uint8List? stampedPostcardData;
  int index = 0;
  bool confirming = false;
  Timer? timer;
  bool alreadyShowPopup = false;
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();
  final _tokenService = injector<TokensService>();
  final _navigationService = injector<NavigationService>();

  @override
  void initState() {
    log.info('[POSTCARD][StampPreview] payload: ${widget.payload.toString()}');
    _configurationService.setAutoShowPostcard(false);
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

  void _setTimer() {
    timer?.cancel();
    const duration = Duration(seconds: 10);
    timer = Timer.periodic(duration, (timer) {
      if (mounted) {
        _refreshPostcard();
      }
    });
  }

  Future<void> showOptions(BuildContext context, {Function()? callBack}) async {
    final theme = Theme.of(context);
    final options = [
      OptionItem(
        title: "stamp_minted".tr(),
        titleStyle: theme.textTheme.moMASans700Black16
            .copyWith(color: MoMAColors.moMA1, fontSize: 18),
        icon: SvgPicture.asset("assets/images/moma_arrow_right.svg"),
        onTap: () {},
        separator: const Divider(
          height: 1,
          thickness: 1.0,
          color: Color.fromRGBO(203, 203, 203, 1),
        ),
      ),
      OptionItem(
        title: 'share_on_'.tr(),
        icon: SvgPicture.asset(
          'assets/images/globe.svg',
          width: 24,
          height: 24,
        ),
        iconOnProcessing: SvgPicture.asset(
          'assets/images/globe.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColor.disabledColor,
            BlendMode.srcIn,
          ),
        ),
        onTap: () async {
          shareToTwitter(token: widget.payload.asset);
          Navigator.of(context).pop();
          await callBack?.call();
        },
      ),
      OptionItem(
        title: 'download_stamp'.tr(),
        icon: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
        ),
        iconOnProcessing: SvgPicture.asset(
          'assets/images/download.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColor.disabledColor,
            BlendMode.srcIn,
          ),
        ),
        onTap: () async {
          try {
            final asset = widget.payload.asset;
            await _postcardService.downloadStamp(
                tokenId: asset.tokenId!, stampIndex: 0);
            if (!mounted) return;
            Navigator.of(context).pop();
            await UIHelper.showPostcardStampSaved(context);
            await callBack?.call();
          } catch (e) {
            log.info("Download stamp failed: error ${e.toString()}");
            if (!mounted) return;
            Navigator.of(context).pop();

            switch (e.runtimeType) {
              case MediaPermissionException:
                await UIHelper.showPostcardStampPhotoAccessFailed(context);
                break;
              default:
                if (!mounted) return;
                await UIHelper.showPostcardStampSavedFailed(context);
            }
            await callBack?.call();
          }
        },
      ),
    ];
    await UIHelper.showPostcardDrawerAction(context, options: options);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const backgroundColor = AppColor.chatPrimaryColor;
    return WillPopScope(
      onWillPop: () async {
        return !confirming;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: !confirming
            ? getBackAppBar(context,
                title: "preview_postcard".tr(),
                titleStyle:
                    theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
                onBack: confirming
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                withDivider: false,
                statusBarColor: backgroundColor)
            : getCloseAppBar(
                context,
                title: "preview_postcard".tr(),
                titleStyle: theme.textTheme.moMASans700Black16.copyWith(
                  fontSize: 18,
                ),
                onClose: () {
                  _navigationService.popUntilHomeOrSettings();
                  if (!mounted) return;
                  Navigator.of(context).pushNamed(
                    AppRouter.claimedPostcardDetailsPage,
                    arguments: PostcardDetailPagePayload(
                        [widget.payload.asset.identity], 0),
                  );
                  _configurationService.setAutoShowPostcard(true);
                },
                withBottomDivider: false,
                statusBarColor: backgroundColor,
              ),
        body: BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
          listener: (context, state) {
            if (!(state.isPostcardUpdatingOnBlockchain ||
                state.isPostcardUpdating)) {
              if (state.assetToken == null) {
                return;
              }
              timer?.cancel();
              if (alreadyShowPopup) {
                return;
              }
              alreadyShowPopup = true;
              showOptions(context, callBack: () {
                log.info("Popup closed");
                _navigationService.popUntilHomeOrSettings();
                if (!mounted) return;
                Navigator.of(context).pushNamed(
                  AppRouter.claimedPostcardDetailsPage,
                  arguments: PostcardDetailPagePayload(
                      [state.assetToken!.identity], 0),
                );
                _configurationService.setAutoShowPostcard(true);
              });
            }
          },
          builder: (context, state) {
            final assetToken = widget.payload.asset;
            final imagePath = widget.payload.imagePath;
            final metadataPath = widget.payload.metadataPath;
            return Padding(
              padding:
                  ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
              child: Column(
                children: [
                  const SizedBox(
                    height: 170,
                  ),
                  PostcardRatio(
                    assetToken: assetToken,
                    imagePath: imagePath,
                    jsonPath: metadataPath,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _postcardAction(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _postcardAction(PostcardDetailState state) {
    final theme = Theme.of(context);
    if (!confirming) {
      return PostcardButton(
        text: widget.payload.asset.postcardMetadata.isCompleted
            ? "complete_postcard_journey_".tr()
            : "confirm_your_design".tr(),
        fontSize: 18,
        onTap: () async {
          await _onConfirm();
        },
      );
    }
    if (state.isPostcardUpdatingOnBlockchain || state.isPostcardUpdating) {
      return PostcardCustomButton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "updating_token".tr(),
              style: theme.textTheme.moMASans700Black14.copyWith(fontSize: 18),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: DotsLoading(),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _onConfirm() async {
    setState(() {
      confirming = true;
    });
    final imagePath = widget.payload.imagePath;
    final metadataPath = widget.payload.metadataPath;
    File imageFile = File(imagePath);
    File metadataFile = File(metadataPath);

    final asset = widget.payload.asset;
    final tokenId = asset.tokenId ?? "";
    final address = asset.owner;
    final counter = asset.postcardMetadata.counter;
    final contractAddress = Environment.postcardContractAddress;

    final walletIndex = await asset.getOwnerWallet();
    if (walletIndex == null) {
      log.info("[POSTCARD] Wallet index not found");
      setState(() {
        confirming = true;
      });
      return;
    }

    final isStampSuccess = await _postcardService.stampPostcard(
        tokenId,
        walletIndex.first,
        walletIndex.second,
        imageFile,
        metadataFile,
        widget.payload.location,
        counter,
        contractAddress);
    if (!isStampSuccess) {
      log.info("[POSTCARD] Stamp failed");
      injector<NavigationService>().popUntilHomeOrSettings();
    } else {
      log.info("[POSTCARD] Stamp success");
      _postcardService.updateStampingPostcard([
        StampingPostcard(
          indexId: asset.id,
          address: address,
          imagePath: imagePath,
          metadataPath: metadataPath,
          counter: counter,
        )
      ]);

      if (widget.payload.location != null) {
        var postcardMetadata = asset.postcardMetadata;
        final stampedLocation = widget.payload.location!;
        postcardMetadata.locationInformation.last.stampedLocation =
            stampedLocation;
        var newAsset = asset.asset;
        newAsset?.artworkMetadata = jsonEncode(postcardMetadata.toJson());
        final pendingToken = asset.copyWith(asset: newAsset);
        await _tokenService.setCustomTokens([pendingToken]);
        _tokenService.reindexAddresses([address]);
        NftCollectionBloc.eventController.add(
          GetTokensByOwnerEvent(pageKey: PageKey.init()),
        );
        _setTimer();
      }
    }
  }
}

class StampPreviewPayload {
  final AssetToken asset;
  final String imagePath;
  final String metadataPath;
  final Location? location;

  // constructor
  StampPreviewPayload({
    required this.asset,
    required this.imagePath,
    required this.metadataPath,
    this.location,
  });
}

class StampingPostcard {
  final String indexId;
  final String address;
  final DateTime timestamp;
  final String imagePath;
  final String metadataPath;
  final int counter;

  // constructor
  StampingPostcard({
    required this.indexId,
    required this.address,
    required this.imagePath,
    required this.metadataPath,
    required this.counter,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  //constructor

  static StampingPostcard fromJson(Map<String, dynamic> json) {
    return StampingPostcard(
      indexId: json['indexId'],
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      metadataPath: json['metadataPath'],
      counter: json['counter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indexId': indexId,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'metadataPath': metadataPath,
      'counter': counter,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StampingPostcard &&
          runtimeType == other.runtimeType &&
          indexId == other.indexId &&
          address == other.address &&
          counter == other.counter;

  @override
  int get hashCode => indexId.hashCode ^ address.hashCode ^ counter.hashCode;
}
