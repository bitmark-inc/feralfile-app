//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:nft_rendering/nft_rendering.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String snakeToCapital() {
    return replaceAll("_", " ").capitalize();
  }

  String mask(int number) {
    if (isEmpty) {
      return "[]";
    } else if (length <= number) {
      return this;
    }
    return maskOnly(number);
  }

  String maskOnly(int number) {
    if (isEmpty) {
      return "";
    } else if (length <= number) {
      return this;
    }
    return "${substring(0, number)}...${substring(length - number, length)}";
  }

  String maskIfNeeded() {
    if (contains(' ')) return this;
    return (length >= 36) ? mask(4) : this;
  }

  String? toIdentityOrMask(Map<String, String>? identityMap) {
    if (isEmpty) return null;
    final identity = identityMap?[this];
    return (identity != null && identity.isNotEmpty)
        ? identity
        : maskIfNeeded();
  }

  bool isValidUrl() {
    return Uri.tryParse(this) != null;
  }

  String replacePrefix(String from, String to) {
    if (startsWith(from)) {
      return replaceRange(0, from.length, to);
    }
    return this;
  }

  String toUrl() {
    if (!startsWith("https://") && !startsWith("http://")) {
      return "https://$this";
    }

    return this;
  }

  String? get blockchainForAddress {
    switch (length) {
      case 42:
        return "ethereum";
      case 36:
        return "tezos";
      default:
        return null;
    }
  }

  bool get isPostcardId {
    final splitted = split('-');
    return splitted.length > 1 &&
        splitted[1] == Environment.postcardContractAddress;
  }

  bool get isAutonomyDocumentLink {
    return (startsWith(AUTONOMY_DOCUMENT_PREFIX) ||
            startsWith(AUTONOMY_RAW_DOCUMENT_PREFIX)) &&
        endsWith(MARKDOWN_EXT);
  }

  String get autonomyRawDocumentLink {
    return replaceFirst(AUTONOMY_DOCUMENT_PREFIX, AUTONOMY_RAW_DOCUMENT_PREFIX)
        .replaceFirst("/blob/", "/");
  }

  String get toMimeType {
    final mimeType = this;
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
        return mimeType;
    }
  }
}
