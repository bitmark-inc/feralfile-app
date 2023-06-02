import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  bool stamped = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar:
          getBackAppBar(context, title: "preview_postcard".tr(), onBack: () {
        Navigator.of(context).pop();
      }, isWhite: false),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PostcardRatio(
              assetToken: widget.payload.asset,
              imagePath: widget.payload.imagePath,
              jsonPath: widget.payload.metadataPath,
            ),
            PostcardButton(
              text: widget.payload.asset.postcardMetadata.isCompleted
                  ? "complete_postcard_journey_".tr()
                  : "confirm_your_design".tr(),
              onTap: () async {
                await _close();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _close() async {
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
      // setState(() {
      //   loading = false;
      // });
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
        final stampedLocation = Location(
            lat: widget.payload.location!.latitude,
            lon: widget.payload.location!.longitude);
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
      }
      _navigationService.popUntilHomeOrSettings();
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRouter.claimedPostcardDetailsPage,
        arguments: ArtworkDetailPayload([asset.identity], 0),
      );
      _configurationService.setAutoShowPostcard(true);
    }
  }
}

class StampPreviewPayload {
  final AssetToken asset;
  final String imagePath;
  final String metadataPath;
  final Position? location;

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
