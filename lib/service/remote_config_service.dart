import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class RemoteConfigService {
  Future<void> loadConfigs();

  bool getBool(final ConfigGroup group, final ConfigKey key);

  T getConfig<T>(final ConfigGroup group, final ConfigKey key, T defaultValue);
}

class RemoteConfigServiceImpl implements RemoteConfigService {
  RemoteConfigServiceImpl(this._pubdocAPI);

  static const String keyRights = 'rights';
  final PubdocAPI _pubdocAPI;

  static const Map<String, dynamic> _defaults = <String, dynamic>{
    'merchandise': {
      'enable': false,
      'allow_view_only': false,
      'must_complete': true,
      'postcard_tokenId_regex': r'^[]$'
    },
    'pay_to_mint': {'enable': true, 'allow_view_only': true},
    'view_detail': {
      'action_button': true,
      'leader_board': true,
      'about_moma': true,
      'glossary': true,
      'metadata': true,
      'token_ownership': true,
      'provenance': true,
      'rights': true,
      'chat': true
    },
    'feature': {'download_stamp': true, 'download_postcard': true},
    'postcard_action': {'wait_confirmed_to_send': false},
    'feralfile_artwork_action': {
      'allow_download_artwork_contracts': [],
      'sound_piece_contract_addresses': [],
      'scrollable_preview_url': [],
    },
    'exhibition': {
      'specified_series_artwork_model_title': {
        'faa810f7-7b75-4c02-bf8a-b7447a89c921': 'interactive instruction'
      },
      'yoko_ono_public': {
        'owner_data_contract': '0xcE6B8E357aaf9EC3A5ACD2F47364586BCF54Afef',
        'moma_exhibition_contract':
            '0xf31725F011cEB81D4cc313349a5942C31ed0AAe5',
        'public_token_id': '1878818250871676369035922701317177438642275461',
        'public_version_preview':
            'previews/d15cc1f3-c2f1-4b9c-837d-7c131583bf40/1710123470/index.html',
        'public_version_thumbnail':
            'thumbnails/d15cc1f3-c2f1-4b9c-837d-7c131583bf40/1710123327'
      }
    },
    'in_app_webview': {
      'uri_scheme_white_list': ['https'],
      'allowed_fingerprints': [],
    },
    'dApp_urls': {
      'deny_dApp_list': [],
    }
  };

  static Map<String, dynamic>? _configs;

  @override
  Future<void> loadConfigs() async {
    try {
      final data = await _pubdocAPI.getConfigs();
      _configs = jsonDecode(data) as Map<String, dynamic>;
      log.fine('RemoteConfigService: loadConfigs: $_configs');
    } catch (e) {
      log.warning('RemoteConfigService: loadConfigs: $e');
    }
  }

  @override
  bool getBool(final ConfigGroup group, final ConfigKey key) {
    if (_configs == null) {
      unawaited(loadConfigs());
      return _defaults[group.getString]![key.getString] as bool;
    } else {
      return _configs![group.getString]?[key.getString] as bool? ??
          _defaults[group.getString]?[key.getString] as bool? ??
          false;
    }
  }

  @override
  T getConfig<T>(final ConfigGroup group, final ConfigKey key, T defaultValue) {
    if (_configs == null) {
      unawaited(loadConfigs());
      return _defaults[group.getString]![key.getString] as T ?? defaultValue;
    } else {
      final hasKey = (_configs?.keys.contains(group.getString) ?? false) &&
          (_configs![group.getString] as Map<String, dynamic>)
              .keys
              .contains(key.getString);
      if (!hasKey) {
        return defaultValue;
      }
      final res = _configs![group.getString]?[key.getString] as T;
      return res;
    }
  }
}

enum ConfigGroup {
  merchandise,
  payToMint,
  viewDetail,
  feature,
  postcardAction,
  feralfileArtworkAction,
  inAppWebView,
  dAppUrls,
  exhibition,
}

// ConfigGroup getString extension
extension ConfigGroupExtension on ConfigGroup {
  String get getString {
    switch (this) {
      case ConfigGroup.merchandise:
        return 'merchandise';
      case ConfigGroup.payToMint:
        return 'pay_to_mint';
      case ConfigGroup.viewDetail:
        return 'view_detail';
      case ConfigGroup.feature:
        return 'feature';
      case ConfigGroup.postcardAction:
        return 'postcard_action';
      case ConfigGroup.feralfileArtworkAction:
        return 'feralfile_artwork_action';
      case ConfigGroup.inAppWebView:
        return 'in_app_webview';
      case ConfigGroup.dAppUrls:
        return 'dApp_urls';
      case ConfigGroup.exhibition:
        return 'exhibition';
    }
  }
}

enum ConfigKey {
  enable,
  allowViewOnly,
  mustCompleted,
  postcardTokenIdRegex,
  actionButton,
  leaderBoard,
  aboutMoma,
  glossary,
  metadata,
  tokenOwnership,
  provenance,
  rights,
  downloadStamp,
  downloadPostcard,
  chat,
  waitConfirmedToSend,
  allowDownloadArtworkContracts,
  soundPieceContractAddresses,
  scrollablePreviewUrl,
  specifiedSeriesArtworkModelTitle,
  yokoOnoPublic,
  yokoOnoPrivateTokenIds,
  uriSchemeWhiteList,
  denyDAppList,
  allowedFingerprints,
}

// ConfigKey getString extension
extension ConfigKeyExtension on ConfigKey {
  String get getString {
    switch (this) {
      case ConfigKey.enable:
        return 'enable';
      case ConfigKey.allowViewOnly:
        return 'allow_view_only';
      case ConfigKey.mustCompleted:
        return 'must_complete';
      case ConfigKey.postcardTokenIdRegex:
        return 'postcard_tokenId_regex';
      case ConfigKey.actionButton:
        return 'action_button';
      case ConfigKey.leaderBoard:
        return 'leader_board';
      case ConfigKey.aboutMoma:
        return 'about_moma';
      case ConfigKey.glossary:
        return 'glossary';
      case ConfigKey.metadata:
        return 'metadata';
      case ConfigKey.tokenOwnership:
        return 'token_ownership';
      case ConfigKey.provenance:
        return 'provenance';
      case ConfigKey.rights:
        return 'rights';
      case ConfigKey.downloadStamp:
        return 'download_stamp';
      case ConfigKey.downloadPostcard:
        return 'download_postcard';
      case ConfigKey.chat:
        return 'chat';
      case ConfigKey.waitConfirmedToSend:
        return 'wait_confirmed_to_send';
      case ConfigKey.allowDownloadArtworkContracts:
        return 'allow_download_artwork_contracts';
      case ConfigKey.soundPieceContractAddresses:
        return 'sound_piece_contract_addresses';
      case ConfigKey.scrollablePreviewUrl:
        return 'scrollable_preview_url';
      case ConfigKey.specifiedSeriesArtworkModelTitle:
        return 'specified_series_artwork_model_title';
      case ConfigKey.yokoOnoPublic:
        return 'yoko_ono_public';
      case ConfigKey.yokoOnoPrivateTokenIds:
        return 'yoko_ono_private_token_ids';
      case ConfigKey.uriSchemeWhiteList:
        return 'uri_scheme_white_list';
      case ConfigKey.denyDAppList:
        return 'deny_dApp_list';
      case ConfigKey.allowedFingerprints:
        return 'allowed_fingerprints';
    }
  }
}
