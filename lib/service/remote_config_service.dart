import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class RemoteConfigService {
  Future<void> loadConfigs();

  bool getBool(final String group, final String key);

  static const String grMerchandise = 'merchandise';
  static const String grPayToMint = 'pay_to_mint';
  static const String grViewDetail = 'view_detail';
  static const String grFeature = 'feature';
  static const String grPostcardAction = 'postcard_action';

  static const String keyEnable = 'enable';
  static const String keyAllowViewOnly = 'allow_view_only';
  static const String keyMustCompleted = 'must_complete';
  static const String keyActionButton = 'action_button';
  static const String keyLeaderBoard = 'leader_board';
  static const String keyAboutMoma = 'about_moma';
  static const String keyGlossary = 'glossary';
  static const String keyMetadata = 'metadata';
  static const String keyTokenOwnership = 'token_ownership';
  static const String keyProvenance = 'provenance';
  static const String keyRights = 'rights';
  static const String keyDownloadStamp = 'download_stamp';
  static const String keyDownloadPostcard = 'download_postcard';
  static const String keyChat = 'chat';
}

class RemoteConfigServiceImpl implements RemoteConfigService {
  RemoteConfigServiceImpl(this._pubdocAPI);

  static const String keyRights = 'rights';
  final PubdocAPI _pubdocAPI;

  static const Map<String, dynamic> _defaults = <String, dynamic>{
    'merchandise': {
      'enable': true,
      'allow_view_only': true,
      'must_complete': true
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
    'postcard_action': {'wait_confirmed_to_send': false}
  };

  static Map<String, dynamic>? _configs;

  @override
  Future<void> loadConfigs() async {
    final data = await _pubdocAPI.getConfigs();
    _configs = jsonDecode(data) as Map<String, dynamic>;
    log.info('RemoteConfigService: loadConfigs: $_configs');
  }

  @override
  bool getBool(final String group, final String key) {
    if (_configs == null) {
      unawaited(loadConfigs());
      return _defaults[group]![key] as bool;
    } else {
      return _configs![group]![key] as bool;
    }
  }
}
