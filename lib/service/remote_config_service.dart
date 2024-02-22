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
    },
  };

  static Map<String, dynamic>? _configs;

  @override
  Future<void> loadConfigs() async {
    try {
      final data = await _pubdocAPI.getConfigs();
      _configs = jsonDecode(data) as Map<String, dynamic>;
      log.info('RemoteConfigService: loadConfigs: $_configs');
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
      final res =
          _configs![group.getString]?[key.getString] as T ?? defaultValue;
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
    }
  }
}
