import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';

extension AssetTokenExtension on AssetToken {
  static final Map<String, Map<String, String>> _tokenUrlMap = {
    "MAIN": {
      "ethereum": "https://etherscan.io/token/{contract}?a={tokenId}",
      "tezos": "https://tzkt.io/{contract}/tokens/{tokenId}/transfers"
    },
    "TEST": {
      "ethereum": "https://goerli.etherscan.io/token/{contract}?a={tokenId}",
      "tezos":
          "https://kathmandunet.tzkt.io/{contract}/tokens/{tokenId}/transfers"
    }
  };

  bool get hasMetadata {
    // FIXME
    return galleryThumbnailURL != null;
  }

  bool get isAirdrop {
    final saleModel = initialSaleModel?.toLowerCase();
    return ["airdrop", "shopping_airdrop"].contains(saleModel);
  }

  ArtworkIdentity get identity => ArtworkIdentity(id, owner);

  String? get tokenURL {
    final network = Environment.appTestnetConfig ? "TEST" : "MAIN";
    final url = _tokenUrlMap[network]?[blockchain]
        ?.replaceAll("{tokenId}", tokenId ?? "")
        .replaceAll("{contract}", contractAddress ?? "");
    return url;
  }

  String get editionSlashMax {
    final editionStr = (editionName != null && editionName!.isNotEmpty)
        ? editionName
        : edition.toString();
    final hasNumber = RegExp(r'[0-9]').hasMatch(editionStr!);
    final maxEditionStr =
        (((maxEdition ?? 0) > 0) && hasNumber) ? "/$maxEdition" : "";
    return "$editionStr$maxEditionStr";
  }

  Future<Pair<WalletStorage, int>?> getOwnerWallet(
      {bool checkContract = true}) async {
    if ((checkContract && contractAddress == null) || tokenId == null)
      return null;
    if (!(blockchain == "ethereum" &&
            (contractType == "erc721" || contractType == "erc1155")) &&
        !(blockchain == "tezos" && contractType == "fa2")) return null;

    //check asset is able to send
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();

    Pair<WalletStorage, int>? result;
    for (final persona in personas) {
      int? index;
      if (blockchain == "ethereum") {
        index = await persona.getEthAddressIndex(owner);
      } else {
        index = await persona.getTezAddressIndex(owner);
      }
      if (index != null) {
        result = Pair<WalletStorage, int>(persona.wallet(), index);
        break;
      }
    }
    return result;
  }

  String _intToHex(String intValue) {
    try {
      final hex = BigInt.parse(intValue, radix: 10).toRadixString(16);
      return hex.padLeft(64, "0");
    } catch (e) {
      return intValue;
    }
  }

  String? tokenIdHex() => tokenId != null ? _intToHex(tokenId!) : null;

  String digestHex2Hash(String tokenId) {
    final bigint = BigInt.tryParse(tokenId, radix: 10);
    if (bigint == null) {
      log.info('digestHex2Hash convert BigInt null');
      return '';
    }

    String hex = bigint.toRadixString(16);
    if (hex.length.isOdd) {
      hex = '0$hex';
    }
    final bytes = hexToBytes(hex);
    final hashHex = '0x${sha256.convert(bytes).toString()}';
    return hashHex;
  }

  String? getPreviewUrl() {
    if (previewURL != null) {
      final url = medium == null
          ? previewURL!
          : _replaceIPFSPreviewURL(previewURL!, medium!);
      return url;
    }
    return null;
  }

  String? getBlockchainUrl() {
    final network = Environment.appTestnetConfig ? "TESTNET" : "MAINNET";
    switch ("${network}_$blockchain") {
      case "MAINNET_ethereum":
        return "https://etherscan.io/address/$contractAddress";

      case "TESTNET_ethereum":
        return "https://goerli.etherscan.io/address/$contractAddress";

      case "MAINNET_tezos":
      case "TESTNET_tezos":
        return "https://tzkt.io/$contractAddress";

      case "MAINNET_bitmark":
        return "https://registry.bitmark.com/bitmark/$tokenId";

      case "TESTNET_bitmark":
        return "https://registry.test.bitmark.com/bitmark/$tokenId";
    }
    return null;
  }

  String get getMimeType {
    switch (mimeType) {
      case "image/avif":
      case "image/bmp":
      case "image/jpeg":
      case "image/jpg":
      case "image/png":
      case "image/tiff":
        return RenderingType.image;

      case "image/svg+xml":
        return RenderingType.svg;

      case "image/gif":
        return RenderingType.gif;

      case "audio/aac":
      case "audio/midi":
      case "audio/x-midi":
      case "audio/mpeg":
      case "audio/ogg":
      case "audio/opus":
      case "audio/wav":
      case "audio/webm":
      case "audio/3gpp":
      case "audio/vnd.wave":
        return RenderingType.audio;

      case "video/x-msvideo":
      case "video/3gpp":
      case "video/mp4":
      case "video/mpeg":
      case "video/ogg":
      case "video/3gpp2":
      case "video/quicktime":
      case "application/x-mpegURL":
      case "video/x-flv":
      case "video/MP2T":
      case "video/webm":
      case "application/octet-stream":
        return RenderingType.video;

      case "application/pdf":
        return RenderingType.pdf;

      case "model/gltf-binary":
        return RenderingType.modelViewer;

      default:
        if (mimeType?.isNotEmpty ?? false) {
          Sentry.captureMessage(
            'Unsupport mimeType: $mimeType',
            level: SentryLevel.warning,
            params: [id],
          );
        }
        return mimeType ?? RenderingType.webview;
    }
  }

  String? getGalleryThumbnailUrl({usingThumbnailID = true}) {
    if (galleryThumbnailURL == null || galleryThumbnailURL!.isEmpty) {
      return null;
    }

    if (usingThumbnailID) {
      if (thumbnailID == null || thumbnailID!.isEmpty) {
        return null;
      }
      return _refineToCloudflareURL(
          galleryThumbnailURL!, thumbnailID!, "thumbnail");
    }

    return _replaceIPFS(galleryThumbnailURL!);
  }

  int? get getCurrentBalance {
    if (balance == null) {
      return null;
    }
    final sentTokens = injector<ConfigurationService>().getRecentlySentToken();
    final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

    final totalSentQuantity = sentTokens
        .where((element) =>
            element.tokenID == id &&
            element.address == owner &&
            element.timestamp.isAfter(expiredTime))
        .fold<int>(0,
            (previousValue, element) => previousValue + element.sentQuantity);
    return balance! - totalSentQuantity;
  }

  bool get isSending {
    final sharedPostcards =
        injector<ConfigurationService>().getSharedPostcard();
    return sharedPostcards.any((element) => (element.tokenID == id &&
        element.owner == lastOwner &&
        owner == lastOwner));
  }

  bool get isStamping {
    final stampingPostcard = injector<PostcardService>().getStampingPostcard();
    return stampingPostcard.any((element) {
      final bool = (element.indexId == id &&
          element.address == owner &&
          owner == lastOwner);
      return bool;
    });
  }

  String get lastOwner {
    return postcardMetadata.lastOwner;
  }

  PostcardMetadata get postcardMetadata {
    return PostcardMetadata.fromJson(jsonDecode(asset!.artworkMetadata!));
  }

  Future<List<TravelInfo>> get listTravelInfo async {
    final stamps = postcardMetadata.locationInformation;

    final travelInfo = <TravelInfo>[];
    for (int i = 0; i < stamps.length - 1; i++) {
      travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i));
    }

    await Future.wait(travelInfo.map((e) async {
      await e.getLocationName();
    }));

    if (travelInfo.length > 44) {
      travelInfo.removeLast();
    }
    return travelInfo;
  }

  List<TravelInfo> get listTravelInfoWithoutLocationName {
    final stamps = postcardMetadata.locationInformation;

    final travelInfo = <TravelInfo>[];
    for (int i = 0; i < stamps.length - 1; i++) {
      travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i));
    }

    if (travelInfo.length > 44) {
      travelInfo.removeLast();
    }
    return travelInfo;
  }

  String get twitterCaption {
    return "Here is Twitter Caption From Asset";
  }

  bool get canShare {
    return owner == postcardMetadata.lastOwner;
  }

  bool get isPostcard => source == "autonomy-postcard";

  int? get counter {
    return postcardMetadata.locationInformation.length;
  }

  bool get isStamped {
    return postcardMetadata.isStamped;
  }

  bool get isFinal {
    return false;
  }

  bool get isCompleted {
    return isFinal && isStamped;
  }
}

extension CompactedAssetTokenExtension on CompactedAssetToken {
  bool get hasMetadata {
    return galleryThumbnailURL != null;
  }

  ArtworkIdentity get identity => ArtworkIdentity(id, owner);

  bool get isPostcard => source == "autonomy-postcard";

  String get getMimeType {
    switch (mimeType) {
      case "image/avif":
      case "image/bmp":
      case "image/jpeg":
      case "image/jpg":
      case "image/png":
      case "image/tiff":
        return RenderingType.image;

      case "image/svg+xml":
        return RenderingType.svg;

      case "image/gif":
        return RenderingType.gif;

      case "audio/aac":
      case "audio/midi":
      case "audio/x-midi":
      case "audio/mpeg":
      case "audio/ogg":
      case "audio/opus":
      case "audio/wav":
      case "audio/webm":
      case "audio/3gpp":
      case "audio/vnd.wave":
        return RenderingType.audio;

      case "video/x-msvideo":
      case "video/3gpp":
      case "video/mp4":
      case "video/mpeg":
      case "video/ogg":
      case "video/3gpp2":
      case "video/quicktime":
      case "application/x-mpegURL":
      case "video/x-flv":
      case "video/MP2T":
      case "video/webm":
      case "application/octet-stream":
        return RenderingType.video;

      case "application/pdf":
        return RenderingType.pdf;

      case "model/gltf-binary":
        return RenderingType.modelViewer;

      default:
        if (mimeType?.isNotEmpty ?? false) {
          Sentry.captureMessage(
            'Unsupport mimeType: $mimeType',
            level: SentryLevel.warning,
            params: [id],
          );
        }
        return mimeType ?? RenderingType.webview;
    }
  }

  String? getGalleryThumbnailUrl({usingThumbnailID = true}) {
    if (galleryThumbnailURL == null || galleryThumbnailURL!.isEmpty) {
      return null;
    }

    if (galleryThumbnailURL!.contains('cdn.feralfileassets.com')) {
      return galleryThumbnailURL;
    }

    if (usingThumbnailID) {
      if (thumbnailID == null || thumbnailID!.isEmpty) {
        return _replaceIPFS(galleryThumbnailURL!); // return null;
      }
      return _refineToCloudflareURL(
          galleryThumbnailURL!, thumbnailID!, "thumbnail");
    }

    return _replaceIPFS(galleryThumbnailURL!);
  }
}

String _replaceIPFSPreviewURL(String url, String medium) {
  // Don't replace CloudflareIPFS in iOS
  // iOS can't render a cloudfare video issue
  // More information: https://stackoverflow.com/questions/33823411/avplayer-fails-to-play-video-sometimes
  // if (Platform.isIOS && medium == 'video') {
  //   return url;
  // }

  url =
      url.replacePrefix(IPFS_PREFIX, "${Environment.autonomyIpfsPrefix}/ipfs/");
  return url.replacePrefix(DEFAULT_IPFS_PREFIX, Environment.autonomyIpfsPrefix);
}

String _replaceIPFS(String url) {
  url =
      url.replacePrefix(IPFS_PREFIX, "${Environment.autonomyIpfsPrefix}/ipfs/");
  return url.replacePrefix(DEFAULT_IPFS_PREFIX, Environment.autonomyIpfsPrefix);
}

String _refineToCloudflareURL(String url, String thumbnailID, String variant) {
  final cloudFlareImageUrlPrefix = Environment.cloudFlareImageUrlPrefix;
  return thumbnailID.isEmpty
      ? _replaceIPFS(url)
      : "$cloudFlareImageUrlPrefix$thumbnailID/$variant";
}

AssetToken createPendingAssetToken({
  required FFArtwork artwork,
  required String owner,
  required String tokenId,
}) {
  final indexerId = artwork.airdropInfo?.getTokenIndexerId(tokenId);
  final artist = artwork.artist;
  final exhibition = artwork.exhibition;
  final contract = artwork.contract;
  return AssetToken(
    asset: Asset(
      indexerId,
      '',
      DateTime.now(),
      artist?.id,
      artist?.fullName,
      null,
      null,
      artwork.title,
      artwork.description,
      null,
      null,
      artwork.maxEdition,
      "airdrop",
      null,
      artwork.thumbnailFileURI,
      artwork.thumbnailFileURI,
      artwork.galleryThumbnailFileURI,
      null,
      null,
      "airdrop",
      null,
      null,
      null,
    ),
    blockchain: exhibition?.mintBlockchain.toLowerCase() ?? "tezos",
    fungible: false,
    contractType: '',
    tokenId: tokenId,
    contractAddress: contract?.address,
    edition: 0,
    editionName: "",
    id: indexerId ?? "",
    mintedAt: artwork.createdAt ?? DateTime.now(),
    balance: 1,
    owner: owner,
    owners: {
      owner: 1,
    },
    lastActivityTime: DateTime.now(),
    lastRefreshedTime: DateTime(1),
    pending: true,
    originTokenInfo: [],
    provenance: [],
  );
}
