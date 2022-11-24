import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uri/uri.dart';
import 'iterable_ext.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
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

  String? get tokenURL {
    final network = Environment.appTestnetConfig ? "TEST" : "MAIN";
    final url = _tokenUrlMap[network]?[blockchain]
        ?.replaceAll("{tokenId}", tokenId ?? "")
        .replaceAll("{contract}", contractAddress ?? "");
    return url;
  }

  Future<WalletStorage?> getOwnerWallet() async {
    if (contractAddress == null || tokenId == null) return null;
    if (!(blockchain == "ethereum" &&
            (contractType == "erc721" || contractType == "erc1155")) &&
        !(blockchain == "tezos" && contractType == "fa2")) return null;

    //check asset is able to send
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();

    WalletStorage? wallet;
    for (final persona in personas) {
      final String address;
      if (blockchain == "ethereum") {
        address = await persona.wallet().getETHEip55Address();
      } else {
        address = (await persona.wallet().getTezosAddress());
      }
      if (ownerAddress == address) {
        wallet = persona.wallet();
        break;
      }
    }
    return wallet;
  }

  String _intToHex(String intValue) {
    try {
      final hex = BigInt.parse(intValue, radix: 10).toRadixString(16);
      return hex.padLeft(64, "0");
    } catch (e) {
      return intValue;
    }
  }

  String _multiUniqueUrl(String originUrl) {
    try {
      final uri = Uri.parse(originUrl);
      final builder = UriBuilder.fromUri(uri);
      final id = (contractAddress == "KT1F6EKvGq8CKJhgsBy3GUJMSS9KPKn1UD5D")
          ? _intToHex(tokenId!)
          : tokenId;

      builder.queryParameters
        ..putIfAbsent("edition_index", () => "$edition")
        ..putIfAbsent("edition_number", () => "$edition")
        ..putIfAbsent("blockchain", () => blockchain)
        ..putIfAbsent("token_id", () => "$id")
        ..putIfAbsent("contract", () => "$contractAddress");
      if (contractAddress == "KT1F6EKvGq8CKJhgsBy3GUJMSS9KPKn1UD5D" ||
          (builder.queryParameters['token_id_hash']?.isNotEmpty ?? false)) {
        return builder.build().toString();
      }

      final tokenHex = digestHex2Hash(id ?? '');
      builder.queryParameters.putIfAbsent("token_id_hash", () => tokenHex);

      return builder.build().toString();
    } catch (e) {
      return originUrl;
    }
  }

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
      return source?.toLowerCase() == "feralfile" ? _multiUniqueUrl(url) : url;
    }
    return null;
  }

  String get getMimeType {
    switch (mimeType) {
      case "image/avif":
      case "image/bmp":
      case "image/jpeg":
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
        return RenderingType.audio;

      case "video/x-msvideo":
      case "video/3gpp":
      case "video/mp4":
      case "video/mpeg":
      case "video/ogg":
      case "video/3gpp2":
      case "application/x-mpegURL":
        return RenderingType.video;

      case "application/pdf":
        return RenderingType.pdf;

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

  String? getThumbnailUrl() {
    if (thumbnailURL != null && thumbnailID != null) {
      return _refineToCloudflareURL(thumbnailURL!, thumbnailID!, "preview");
    }
    return thumbnailURL;
  }

  String? getGalleryThumbnailUrl() {
    if (galleryThumbnailURL != null && thumbnailID != null) {
      return _refineToCloudflareURL(
          galleryThumbnailURL!, thumbnailID!, "thumbnail");
    }
    return galleryThumbnailURL;
  }

  String? getBlockchainUrl() {
    final network = Environment.appTestnetConfig ? "TESTNET" : "MAINNET";
    String? url = blockchainUrl;
    if (url == null || url.isEmpty != false) {
      switch ("${network}_$blockchain") {
        case "MAINNET_ethereum":
          url = "https://etherscan.io/address/$contractAddress";
          break;

        case "TESTNET_ethereum":
          url = "https://goerli.etherscan.io/address/$contractAddress";
          break;

        case "MAINNET_tezos":
        case "TESTNET_tezos":
          url = "https://tzkt.io/$contractAddress";
          break;

        case "MAINNET_bitmark":
          url = "https://registry.bitmark.com/bitmark/$tokenId";
          break;
        case "TESTNET_bitmark":
          url = "https://registry.test.bitmark.com/bitmark/$tokenId";
          break;
      }
    }
    return url;
  }
}

String _replaceIPFSPreviewURL(String url, String medium) {
  // Don't replace CloudflareIPFS in iOS
  // iOS can't render a cloudfare video issue
  // More information: https://stackoverflow.com/questions/33823411/avplayer-fails-to-play-video-sometimes
  if (Platform.isIOS && medium == 'video') {
    return url;
  }

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
  return thumbnailID.isEmpty
      ? _replaceIPFS(url)
      : "$CLOUDFLAREIMAGEURLPREFIX$thumbnailID/$variant";
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
    artistName: artist.fullName,
    artistURL: null,
    artistID: artist.id,
    assetData: null,
    assetID: null,
    assetURL: null,
    basePrice: null,
    baseCurrency: null,
    blockchain: exhibition?.mintBlockchain.toLowerCase() ?? "tezos",
    blockchainUrl: null,
    fungible: false,
    contractType: null,
    tokenId: tokenId,
    contractAddress: contract?.address,
    desc: artwork.description,
    edition: 0,
    editionName: "",
    id: indexerId ?? "",
    maxEdition: artwork.maxEdition,
    medium: null,
    mimeType: null,
    mintedAt: artwork.createdAt != null
        ? dateFormatterYMDHM.format(artwork.createdAt!).toUpperCase()
        : null,
    previewURL: artwork.thumbnailFileURI,
    source: "airdrop",
    sourceURL: null,
    thumbnailID: null,
    thumbnailURL: artwork.thumbnailFileURI,
    galleryThumbnailURL: artwork.galleryThumbnailFileURI,
    title: artwork.title,
    balance: 0,
    ownerAddress: owner,
    owners: {
      owner: 1,
    },
    lastActivityTime: DateTime.now(),
    pending: true,
    initialSaleModel: "airdrop",
  );
}
