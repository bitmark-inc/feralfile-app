//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

//ignore_for_file: constant_identifier_names

abstract class ConfigurationService {
  int getDailyLikedCount();

  Future<void> setDailyLikedCount(int count);

  String? getAnonymousDeviceId();

  Future<String> createAnonymousDeviceId();

  List<String> getAnonymousIssueIds();

  Future<void> addAnonymousIssueId(List<String> issueIds);

  bool didMigrateToAccountSetting();

  Future<void> setMigrateToAccountSetting(bool value);

  Future<void> setDidShowLiveWithArt(bool value);

  bool didShowLiveWithArt();

  Future<void> setLastPullAnnouncementTime(int lastPullTime);

  int getLastPullAnnouncementTime();

  Future<void> setHasMerchandiseSupport(String indexId,
      {bool value = true, bool isOverride = false});

  bool hasMerchandiseSupport(String indexId);

  Future<void> setPostcardChatConfig(PostcardChatConfig config);

  PostcardChatConfig getPostcardChatConfig(
      {required String address, required String id});

  Future<void> setDidMigrateAddress(bool value);

  bool getDidMigrateAddress();

  Future<void> setAnnouncementLastPullTime(int lastPullTime);

  int? getAnnouncementLastPullTime();

  Future<void> setOldUser();

  bool getIsOldUser();

  Future<void> setIAPReceipt(String? value);

  String? getIAPReceipt();

  Future<void> setIAPJWT(JWT? value);

  JWT? getIAPJWT();

  Future<void> setDevicePasscodeEnabled(bool value);

  bool isDevicePasscodeEnabled();

  Future<void> setNotificationEnabled(bool value);

  bool isNotificationEnabled();

  Future<void> setAnalyticEnabled(bool value);

  bool isAnalyticsEnabled();

  Future<void> setDoneOnboarding(bool value);

  bool isDoneOnboarding();

  DateTime? getLastTimeAskForSubscription();

  Future setLastTimeAskForSubscription(DateTime date);

  List<String> getTempStorageHiddenTokenIDs({Network? network});

  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false});

  List<SentArtwork> getRecentlySentToken();

  Future updateRecentlySentToken(List<SentArtwork> sentArtwork,
      {bool override = false});

  Future<void> setReadReleaseNotesInVersion(String version);

  String? getReadReleaseNotesVersion();

  String? getPreviousBuildNumber();

  Future<void> setPreviousBuildNumber(String value);

  Future<String> getAccountHMACSecret();

  String? lastRemindReviewDate();

  Future<void> setLastRemindReviewDate(String? value);

  int? countOpenApp();

  Future<void> setCountOpenApp(int? value);

  // ----- App Setting -----

  bool showTokenDebugInfo();

  Future setShowTokenDebugInfo(bool show);

  Future setDoneOnboardingTime(DateTime time);

  Future setSubscriptionTime(DateTime time);

  // Do at once

  /// to determine a hash value of the current addresses where
  /// the app checked for Tezos artworks
  int? sentTezosArtworkMetricValue();

  Future setSentTezosArtworkMetric(int hashedAddresses);

  // Reload
  Future<void> reload();

  Future<void> removeAll();

  ValueNotifier<bool> get showingNotification;

  List<SharedPostcard> getSharedPostcard();

  Future<void> updateSharedPostcard(List<SharedPostcard> sharedPostcards,
      {bool override = false, bool isRemoved = false});

  Future<void> removeSharedPostcardWhere(bool Function(SharedPostcard) test);

  List<String> getListPostcardMint();

  Future<void> setListPostcardMint(List<String> tokenID,
      {bool override = false, bool isRemoved = false});

  List<StampingPostcard> getStampingPostcard();

  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false});

  Future<void> setProcessingStampPostcard(List<ProcessingStampPostcard> values,
      {bool override = false, bool isRemove = false});

  List<ProcessingStampPostcard> getProcessingStampPostcard();

  Future<void> setAutoShowPostcard(bool value);

  bool isAutoShowPostcard();

  List<PostcardIdentity> getListPostcardAlreadyShowYouDidIt();

  Future<void> setListPostcardAlreadyShowYouDidIt(List<PostcardIdentity> value,
      {bool override = false});

  Future<void> setAlreadyShowPostcardUpdates(List<PostcardIdentity> value,
      {bool override = false});

  List<PostcardIdentity> getAlreadyShowPostcardUpdates();

  String getVersionInfo();

  Future<void> setVersionInfo(String version);

  List<String> getHiddenOrSentTokenIDs();

  Future<void> setShowPostcardBanner(bool bool);

  bool getShowPostcardBanner();

  Future<void> setShowAddAddressBanner(bool bool);

  bool getShowAddAddressBanner();

  Future<void> setMerchandiseOrderIds(List<String> ids,
      {bool override = false});

  List<String> getMerchandiseOrderIds();

  Future<void> setReferralCode(String referralCode);

  String? getReferralCode();

  void setLinkAnnouncementToIssue(String announcementContentId, String issueId);

  String? getIssueIdByAnnouncementContentId(String announcementContentId);

  String? getAnnouncementContentIdByIssueId(String issueId);
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String keyDailyLikedCount = 'daily_liked_count';
  static const String keyAnonymousDeviceId = 'anonymous_device_id';
  static const String keyAnonymousIssueIds = 'anonymous_issue_ids';
  static const String keyDidMigrateToAccountSetting =
      'did_migrate_to_account_setting';
  static const String keyDidShowLiveWithArt = 'did_show_live_with_art';
  static const String keyLastPullAnnouncementTime =
      'last_pull_announcement_time';
  static const String KEY_HAS_MERCHANDISE_SUPPORT_INDEX_ID =
      'has_merchandise_support';
  static const String KEY_POSTCARD_CHAT_CONFIG = 'postcard_chat_config';
  static const String KEY_DID_MIGRATE_ADDRESS = 'did_migrate_address';
  static const String KEY_HIDDEN_FEEDS = 'hidden_feeds';
  static const String KEY_IAP_RECEIPT = 'key_iap_receipt';
  static const String KEY_IAP_JWT = 'key_iap_jwt';
  static const String IS_PREMIUM = 'is_premium';
  static const String KEY_DEVICE_PASSCODE = 'device_passcode';
  static const String KEY_NOTIFICATION = 'notifications';
  static const String KEY_ANALYTICS = 'analytics';
  static const String KEY_DONE_ONBOARING = 'done_onboarding';
  static const String KEY_LAST_TIME_ASK_SUBSCRIPTION =
      'last_time_ask_subscription';
  static const String KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS =
      'temp_storage_hidden_token_ids_mainnet';
  static const String KEY_RECENTLY_SENT_TOKEN = 'recently_sent_token_mainnet';
  static const String KEY_READ_RELEASE_NOTES_VERSION =
      'read_release_notes_version';
  static const String ACCOUNT_HMAC_SECRET = 'account_hmac_secret';
  static const String KEY_SHARED_POSTCARD = 'shared_postcard';

  static const String ANNOUNCEMENT_LAST_PULL_TIME =
      'announcement_last_pull_time';
  static const String OLD_USER = 'old_user';

  static const String DID_RUN_SETUP = 'did_run_setup';

  static const String KEY_ANNOUNCEMENT_TO_ISSUE_MAP =
      'announcement_to_issue_map';

  // ----- App Setting -----
  static const String KEY_PREVIOUS_BUILD_NUMBER = 'previous_build_number';
  static const String KEY_SHOW_TOKEN_DEBUG_INFO = 'show_token_debug_info';
  static const String LAST_REMIND_REVIEW = 'last_remind_review';
  static const String COUNT_OPEN_APP = 'count_open_app';
  static const String ALLOW_CONTRIBUTION = 'allow_contribution';

  static const String SHOW_AU_CHAIN_INFO = 'show_au_chain_info';

  static const String KEY_DONE_ON_BOARDING_TIME = 'done_on_boarding_time';

  static const String KEY_SUBSCRIPTION_TIME = 'subscription_time';

  static const String KEY_STAMPING_POSTCARD = 'stamping_postcard';

  static const String KEY_AUTO_SHOW_POSTCARD = 'auto_show_postcard';

  static const String KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD =
      'already_show_you_did_it_postcard';

  static const String KEY_CURRENT_GROUP_CHAT_ID = 'current_group_chat_id';

  static const String KEY_ALREADY_SHOW_POSTCARD_UPDATES =
      'already_show_postcard_updates';

  static const String KEY_MIXPANEL_PROPS = 'mixpanel_props';

  static const String KEY_PACKAGE_INFO = 'package_info';

  static const String KEY_PROCESSING_STAMP_POSTCARD =
      'processing_stamp_postcard';

  static const String KEY_SHOW_POSTCARD_BANNER = 'show_postcard_banner';

  static const String KEY_SHOW_ADD_ADDRESS_BANNER = 'show_add_address_banner';

  static const String KEY_MERCHANDISE_ORDER_IDS = 'merchandise_order_ids';

  static const String KEY_REFERRAL_CODE = 'referral_code';

  // Do at once
  static const String KEY_SENT_TEZOS_ARTWORK_METRIC =
      'sent_tezos_artwork_metric';

  static const String POSTCARD_MINT = 'postcard_mint';

  final SharedPreferences _preferences;

  ConfigurationServiceImpl(this._preferences);

  @override
  Future<void> setIAPReceipt(String? value) async {
    if (value != null) {
      await _preferences.setString(KEY_IAP_RECEIPT, value);
    } else {
      await _preferences.remove(KEY_IAP_RECEIPT);
    }
  }

  @override
  String? getIAPReceipt() => _preferences.getString(KEY_IAP_RECEIPT);

  @override
  Future<void> setIAPJWT(JWT? value) async {
    if (value == null) {
      await _preferences.remove(KEY_IAP_JWT);
      return;
    }
    final json = jsonEncode(value);
    await _preferences.setString(KEY_IAP_JWT, json);
  }

  @override
  JWT? getIAPJWT() {
    final data = _preferences.getString(KEY_IAP_JWT);
    if (data == null) {
      return null;
    } else {
      final json = jsonDecode(data);
      return JWT.fromJson(json);
    }
  }

  @override
  bool isDevicePasscodeEnabled() => false; // always enabled

  @override
  Future<void> setDevicePasscodeEnabled(bool value) async {
    log.info('setDevicePasscodeEnabled: $value');
    await _preferences.setBool(KEY_DEVICE_PASSCODE, false);
  }

  @override
  bool isAnalyticsEnabled() => _preferences.getBool(KEY_ANALYTICS) ?? true;

  @override
  bool isNotificationEnabled() =>
      _preferences.getBool(KEY_NOTIFICATION) ?? false;

  @override
  bool isDoneOnboarding() => _preferences.getBool(KEY_DONE_ONBOARING) ?? false;

  @override
  Future<void> setAnalyticEnabled(bool value) async {
    log.info('setAnalyticEnabled: $value');
    await _preferences.setBool(KEY_ANALYTICS, value);
  }

  @override
  Future<void> setDoneOnboarding(bool value) async {
    log.info('setDoneOnboarding: $value');
    final currentValue = isDoneOnboarding();
    await _preferences.setBool(KEY_DONE_ONBOARING, value);

    if (!currentValue && value && !getIsOldUser()) {
      await setDoneOnboardingTime(DateTime.now());
      await setOldUser();
    }
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    log.info('setNotificationEnabled: $value');
    await _preferences.setBool(KEY_NOTIFICATION, value);
  }

  @override
  List<String> getTempStorageHiddenTokenIDs({Network? network}) =>
      _preferences.getStringList(KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS) ?? [];

  @override
  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false}) async {
    const key = KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS;

    if (override && isAdd) {
      await _preferences.setStringList(key, tokenIDs);
    } else {
      var tempHiddenTokenIDs = _preferences.getStringList(key) ?? [];

      isAdd
          ? tempHiddenTokenIDs.addAll(tokenIDs)
          : tempHiddenTokenIDs
              .removeWhere((element) => tokenIDs.contains(element));
      await _preferences.setStringList(
          key, tempHiddenTokenIDs.toSet().toList());
    }
  }

  @override
  List<SentArtwork> getRecentlySentToken() {
    final sentTokensString =
        _preferences.getStringList(KEY_RECENTLY_SENT_TOKEN) ?? [];
    return sentTokensString
        .map((e) => SentArtwork.fromJson(jsonDecode(e)))
        .toList();
  }

  @override
  Future updateRecentlySentToken(List<SentArtwork> sentArtwork,
      {bool override = false}) async {
    const key = KEY_RECENTLY_SENT_TOKEN;
    await _removeExpiredSentToken(
        DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME));
    final updateTokens =
        sentArtwork.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updateTokens);
    } else {
      var sentTokenIDs = _preferences.getStringList(key) ?? []
        ..addAll(updateTokens);
      await _preferences.setStringList(key, sentTokenIDs.toSet().toList());
    }
  }

  Future _removeExpiredSentToken(DateTime timestampExpired) async {
    List<SentArtwork> token = getRecentlySentToken()
      ..removeWhere((element) => element.timestamp.isBefore(timestampExpired));
    await _preferences.setStringList(KEY_RECENTLY_SENT_TOKEN,
        token.map((e) => jsonEncode(e.toJson())).toList());
  }

  @override
  Future<void> setReadReleaseNotesInVersion(String version) async {
    await _preferences.setString(KEY_READ_RELEASE_NOTES_VERSION, version);
  }

  @override
  String? getReadReleaseNotesVersion() =>
      _preferences.getString(KEY_READ_RELEASE_NOTES_VERSION);

  @override
  DateTime? getLastTimeAskForSubscription() {
    final d = _preferences.getInt(KEY_LAST_TIME_ASK_SUBSCRIPTION);
    return d != null ? DateTime.fromMillisecondsSinceEpoch(d) : null;
  }

  @override
  Future setLastTimeAskForSubscription(DateTime date) async {
    await _preferences.setInt(
      KEY_LAST_TIME_ASK_SUBSCRIPTION,
      date.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> reload() => _preferences.reload();

  @override
  Future<void> setPreviousBuildNumber(String value) async {
    await _preferences.setString(KEY_PREVIOUS_BUILD_NUMBER, value);
  }

  @override
  String? getPreviousBuildNumber() =>
      _preferences.getString(KEY_PREVIOUS_BUILD_NUMBER);

  @override
  Future<String> getAccountHMACSecret() async {
    final value = _preferences.getString(ACCOUNT_HMAC_SECRET);
    if (value == null) {
      final setValue = const Uuid().v4();
      await _preferences.setString(ACCOUNT_HMAC_SECRET, setValue);
      return setValue;
    }

    return value;
  }

  @override
  bool showTokenDebugInfo() =>
      _preferences.getBool(KEY_SHOW_TOKEN_DEBUG_INFO) ?? false;

  @override
  Future setShowTokenDebugInfo(bool show) async {
    await _preferences.setBool(KEY_SHOW_TOKEN_DEBUG_INFO, show);
  }

  @override
  Future<void> removeAll() => _preferences.clear();

  @override
  int? sentTezosArtworkMetricValue() =>
      _preferences.getInt(KEY_SENT_TEZOS_ARTWORK_METRIC);

  @override
  Future setSentTezosArtworkMetric(int hashedAddresses) =>
      _preferences.setInt(KEY_SENT_TEZOS_ARTWORK_METRIC, hashedAddresses);

  @override
  String? lastRemindReviewDate() => _preferences.getString(LAST_REMIND_REVIEW);

  @override
  Future<void> setLastRemindReviewDate(String? value) async {
    if (value == null) {
      await _preferences.remove(LAST_REMIND_REVIEW);
      return;
    }
    await _preferences.setString(LAST_REMIND_REVIEW, value);
  }

  @override
  int? countOpenApp() => _preferences.getInt(COUNT_OPEN_APP);

  @override
  Future<void> setCountOpenApp(int? value) async {
    if (value == null) {
      await _preferences.remove(COUNT_OPEN_APP);
      return;
    }
    await _preferences.setInt(COUNT_OPEN_APP, value);
  }

  @override
  int? getAnnouncementLastPullTime() =>
      _preferences.getInt(ANNOUNCEMENT_LAST_PULL_TIME);

  @override
  Future<void> setAnnouncementLastPullTime(int lastPullTime) async {
    await _preferences.setInt(ANNOUNCEMENT_LAST_PULL_TIME, lastPullTime);
  }

  @override
  bool getIsOldUser() => _preferences.getBool(OLD_USER) ?? false;

  @override
  Future<void> setOldUser() async {
    await _preferences.setBool(OLD_USER, true);
  }

  @override
  ValueNotifier<bool> showingNotification = ValueNotifier(false);

  @override
  Future setDoneOnboardingTime(DateTime time) async {
    await _preferences.setString(
        KEY_DONE_ON_BOARDING_TIME, time.toIso8601String());
  }

  @override
  Future setSubscriptionTime(DateTime time) async {
    await _preferences.setString(KEY_SUBSCRIPTION_TIME, time.toIso8601String());
  }

  @override
  List<SharedPostcard> getSharedPostcard() {
    final sharedPostcardString =
        _preferences.getStringList(KEY_SHARED_POSTCARD) ?? [];
    return sharedPostcardString
        .map((e) => SharedPostcard.fromJson(jsonDecode(e)))
        .toSet()
        .toList();
  }

  @override
  Future<void> updateSharedPostcard(List<SharedPostcard> sharedPostcards,
      {bool override = false, bool isRemoved = false}) async {
    const key = KEY_SHARED_POSTCARD;
    final updatePostcards =
        sharedPostcards.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updatePostcards);
    } else {
      var sentPostcard = _preferences.getStringList(key) ?? [];
      if (isRemoved) {
        sentPostcard
            .removeWhere((element) => updatePostcards.contains(element));
      } else {
        sentPostcard.addAll(updatePostcards);
      }
      final uniqueSharedPostcard = sentPostcard
          .map((e) => SharedPostcard.fromJson(jsonDecode(e)))
          .toList()
        ..sort((e1, e2) {
          if (e2.sharedAt == null || e1.sharedAt == null) {
            return 0;
          }
          return e2.sharedAt!.compareTo(e1.sharedAt!);
        })
        ..unique((element) => element.tokenID + element.owner);
      await _preferences.setStringList(key,
          uniqueSharedPostcard.map((e) => jsonEncode(e.toJson())).toList());
    }
  }

  @override
  Future<void> removeSharedPostcardWhere(bool Function(SharedPostcard) test) {
    final sharedPostcardString =
        _preferences.getStringList(KEY_SHARED_POSTCARD) ?? [];
    final sharedPostcards = sharedPostcardString
        .map((e) => SharedPostcard.fromJson(jsonDecode(e)))
        .toSet()
        .toList()
      ..removeWhere(test);
    return updateSharedPostcard(sharedPostcards, override: true);
  }

  @override
  List<String> getListPostcardMint() =>
      _preferences.getStringList(POSTCARD_MINT) ?? [];

  @override
  Future<void> setListPostcardMint(List<String> tokenID,
      {bool override = false, bool isRemoved = false}) async {
    if (override) {
      await _preferences.setStringList(POSTCARD_MINT, tokenID);
    } else {
      var currentPostcardMints =
          _preferences.getStringList(POSTCARD_MINT) ?? [];
      if (isRemoved) {
        currentPostcardMints
            .removeWhere((element) => tokenID.contains(element));
      } else {
        currentPostcardMints.addAll(tokenID);
      }
      await _preferences.setStringList(POSTCARD_MINT, currentPostcardMints);
    }
  }

  @override
  List<StampingPostcard> getStampingPostcard() =>
      _preferences
          .getStringList(KEY_STAMPING_POSTCARD)
          ?.map((e) => StampingPostcard.fromJson(jsonDecode(e)))
          .toList()
          .where((element) => element.timestamp
              .isAfter(DateTime.now().subtract(STAMPING_POSTCARD_LIMIT_TIME)))
          .toList() ??
      [];

  @override
  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false}) async {
    const key = KEY_STAMPING_POSTCARD;
    final updatePostcards = values.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updatePostcards);
    } else {
      var currentStampingPostcard = _preferences.getStringList(key) ?? [];

      if (isRemove) {
        currentStampingPostcard
            .removeWhere((element) => updatePostcards.contains(element));
      } else {
        currentStampingPostcard.addAll(updatePostcards);
      }
      await _preferences.setStringList(
          key, currentStampingPostcard.toSet().toList());
    }
  }

  @override
  bool isAutoShowPostcard() =>
      _preferences.getBool(KEY_AUTO_SHOW_POSTCARD) ?? false;

  @override
  Future<void> setAutoShowPostcard(bool value) async {
    log.info('setAutoShowPostcard: $value');
    await _preferences.setBool(KEY_AUTO_SHOW_POSTCARD, value);
  }

  @override
  List<PostcardIdentity> getListPostcardAlreadyShowYouDidIt() =>
      _preferences
          .getStringList(KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD)
          ?.map((e) => PostcardIdentity.fromJson(jsonDecode(e)))
          .toList() ??
      [];

  @override
  Future<void> setListPostcardAlreadyShowYouDidIt(List<PostcardIdentity> values,
      {bool override = false}) async {
    const key = KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD;
    final updateValues = values.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updateValues);
    } else {
      var currentValue = _preferences.getStringList(key) ?? []
        ..addAll(updateValues);
      await _preferences.setStringList(key, currentValue.toSet().toList());
    }
  }

  @override
  List<PostcardIdentity> getAlreadyShowPostcardUpdates() =>
      _preferences
          .getStringList(KEY_ALREADY_SHOW_POSTCARD_UPDATES)
          ?.map((e) => PostcardIdentity.fromJson(jsonDecode(e)))
          .toList() ??
      [];

  @override
  Future<void> setAlreadyShowPostcardUpdates(List<PostcardIdentity> value,
      {bool override = false}) {
    const key = KEY_ALREADY_SHOW_POSTCARD_UPDATES;
    final updateValues = value.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      return _preferences.setStringList(key, updateValues);
    } else {
      var currentValue = _preferences.getStringList(key) ?? []
        ..addAll(updateValues);
      return _preferences.setStringList(key, currentValue.toSet().toList());
    }
  }

  @override
  String getVersionInfo() => _preferences.getString(KEY_PACKAGE_INFO) ?? '';

  @override
  Future<void> setVersionInfo(String version) async {
    await _preferences.setString(KEY_PACKAGE_INFO, version);
  }

  @override
  bool getDidMigrateAddress() =>
      _preferences.getBool(KEY_DID_MIGRATE_ADDRESS) ?? false;

  @override
  Future<void> setDidMigrateAddress(bool value) async {
    await _preferences.setBool(KEY_DID_MIGRATE_ADDRESS, value);
  }

  @override
  PostcardChatConfig getPostcardChatConfig(
      {required String address, required String id}) {
    final configs = _preferences.getStringList(KEY_POSTCARD_CHAT_CONFIG) ?? [];
    final chatConfigs =
        configs.map((e) => PostcardChatConfig.fromJson(jsonDecode(e))).toList();
    return chatConfigs.firstWhereOrNull(
            (element) => element.address == address && element.tokenId == id) ??
        PostcardChatConfig(address: address, tokenId: id);
  }

  @override
  Future<void> setPostcardChatConfig(PostcardChatConfig config) async {
    final configs = _preferences.getStringList(KEY_POSTCARD_CHAT_CONFIG) ?? [];
    final chatConfigs =
        configs.map((e) => PostcardChatConfig.fromJson(jsonDecode(e))).toList()
          ..removeWhere((element) =>
              element.address == config.address &&
              element.tokenId == config.tokenId)
          ..add(config);
    await _preferences.setStringList(
        KEY_POSTCARD_CHAT_CONFIG,
        chatConfigs
            .map((e) => jsonEncode(e.toJson()))
            .toList()
            .toSet()
            .toList());
  }

  @override
  bool hasMerchandiseSupport(String indexId) {
    final merchandiseSupportIndexIds =
        _preferences.getStringList(KEY_HAS_MERCHANDISE_SUPPORT_INDEX_ID) ?? [];
    return merchandiseSupportIndexIds.contains(indexId);
  }

  @override
  Future<void> setHasMerchandiseSupport(String indexId,
      {bool value = true, bool isOverride = false}) async {
    if (isOverride) {
      await _preferences
          .setStringList(KEY_HAS_MERCHANDISE_SUPPORT_INDEX_ID, [indexId]);
    } else {
      final merchandiseSupportIndexIds =
          _preferences.getStringList(KEY_HAS_MERCHANDISE_SUPPORT_INDEX_ID) ??
              [];
      if (value) {
        merchandiseSupportIndexIds.add(indexId);
        merchandiseSupportIndexIds.toSet().toList();
      } else {
        merchandiseSupportIndexIds.remove(indexId);
      }
      await _preferences.setStringList(
          KEY_HAS_MERCHANDISE_SUPPORT_INDEX_ID, merchandiseSupportIndexIds);
    }
  }

  @override
  List<ProcessingStampPostcard> getProcessingStampPostcard() =>
      _preferences
          .getStringList(KEY_PROCESSING_STAMP_POSTCARD)
          ?.map((e) => ProcessingStampPostcard.fromJson(jsonDecode(e)))
          .toList() ??
      [];

  @override
  Future<void> setProcessingStampPostcard(List<ProcessingStampPostcard> values,
      {bool override = false, bool isRemove = false}) {
    const key = KEY_PROCESSING_STAMP_POSTCARD;
    final updatePostcards = values.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      return _preferences.setStringList(key, updatePostcards);
    } else {
      var currentStampingPostcard = _preferences.getStringList(key) ?? [];

      if (isRemove) {
        currentStampingPostcard
            .removeWhere((element) => updatePostcards.contains(element));
      } else {
        currentStampingPostcard.addAll(updatePostcards);
      }
      return _preferences.setStringList(
          key, currentStampingPostcard.toSet().toList());
    }
  }

  @override
  List<String> getHiddenOrSentTokenIDs() {
    final hiddenTokens = getTempStorageHiddenTokenIDs();
    final recentlySent = getRecentlySentToken();
    log
      ..info('[ConfigurationService] Hidden tokens: $hiddenTokens')
      ..info('[ConfigurationService] Recently sent: $recentlySent');
    hiddenTokens.addAll(recentlySent
        .where((element) => element.isSentAll && !element.isExpired())
        .map((e) => e.tokenID)
        .toList());
    return hiddenTokens;
  }

  @override
  Future<void> setShowPostcardBanner(bool bool) async {
    await _preferences.setBool(KEY_SHOW_POSTCARD_BANNER, bool);
  }

  @override
  bool getShowPostcardBanner() =>
      _preferences.getBool(KEY_SHOW_POSTCARD_BANNER) ?? true;

  @override
  Future<void> setShowAddAddressBanner(bool bool) async {
    await _preferences.setBool(KEY_SHOW_ADD_ADDRESS_BANNER, bool);
  }

  @override
  bool getShowAddAddressBanner() =>
      _preferences.getBool(KEY_SHOW_ADD_ADDRESS_BANNER) ?? true;

  @override
  List<String> getMerchandiseOrderIds() =>
      _preferences.getStringList(KEY_MERCHANDISE_ORDER_IDS) ?? [];

  @override
  Future<void> setMerchandiseOrderIds(List<String> ids,
      {bool override = false}) async {
    if (override) {
      await _preferences.setStringList(KEY_MERCHANDISE_ORDER_IDS, ids);
    } else {
      final currentIds =
          _preferences.getStringList(KEY_MERCHANDISE_ORDER_IDS) ?? []
            ..addAll(ids);
      await _preferences.setStringList(
          KEY_MERCHANDISE_ORDER_IDS, currentIds.toSet().toList());
    }
  }

  @override
  int getLastPullAnnouncementTime() =>
      _preferences.getInt(keyLastPullAnnouncementTime) ?? 0;

  @override
  Future<void> setLastPullAnnouncementTime(int lastPullTime) =>
      _preferences.setInt(keyLastPullAnnouncementTime, lastPullTime);

  @override
  bool didMigrateToAccountSetting() =>
      _preferences.getBool(keyDidMigrateToAccountSetting) ?? false;

  @override
  Future<void> setMigrateToAccountSetting(bool value) =>
      _preferences.setBool(keyDidMigrateToAccountSetting, value);

  @override
  String? getReferralCode() => _preferences.getString(KEY_REFERRAL_CODE);

  @override
  Future<void> setReferralCode(String referralCode) =>
      _preferences.setString(KEY_REFERRAL_CODE, referralCode);

  @override
  bool didShowLiveWithArt() =>
      _preferences.getBool(keyDidShowLiveWithArt) ?? false;

  @override
  Future<void> setDidShowLiveWithArt(bool value) async =>
      await _preferences.setBool(keyDidShowLiveWithArt, value);

  @override
  String? getAnnouncementContentIdByIssueId(String issueId) {
    final map = _preferences.getString(KEY_ANNOUNCEMENT_TO_ISSUE_MAP);
    if (map == null) {
      return null;
    }
    final mapJson = jsonDecode(map) as Map<String, dynamic>;
    return mapJson.entries
        .firstWhereOrNull((element) => element.value == issueId)
        ?.key;
  }

  @override
  String? getIssueIdByAnnouncementContentId(String announcementContentId) {
    final map = _preferences.getString(KEY_ANNOUNCEMENT_TO_ISSUE_MAP);
    if (map == null) {
      return null;
    }
    final mapJson = jsonDecode(map) as Map<String, dynamic>;
    return mapJson[announcementContentId];
  }

  @override
  Future<void> setLinkAnnouncementToIssue(
      String announcementContentId, String issueId) async {
    final map = _preferences.getString(KEY_ANNOUNCEMENT_TO_ISSUE_MAP);
    final mapJson = map == null ? <String, String>{} : jsonDecode(map);
    mapJson[announcementContentId] = issueId;
    await _preferences.setString(
        KEY_ANNOUNCEMENT_TO_ISSUE_MAP, jsonEncode(mapJson));
  }

  @override
  String? getAnonymousDeviceId() =>
      _preferences.getString(keyAnonymousDeviceId);

  @override
  Future<String> createAnonymousDeviceId() async {
    final uuid = const Uuid().v4();
    final anonymousDeviceId = 'device-$uuid';
    await _preferences.setString(keyAnonymousDeviceId, anonymousDeviceId);
    return anonymousDeviceId;
  }

  @override
  Future<void> addAnonymousIssueId(List<String> issueIds) {
    final currentIssueIds = getAnonymousIssueIds()
      ..addAll(issueIds)
      ..unique();
    return _preferences.setStringList(keyAnonymousIssueIds, currentIssueIds);
  }

  @override
  List<String> getAnonymousIssueIds() =>
      _preferences.getStringList(keyAnonymousIssueIds) ?? <String>[];

  @override
  int getDailyLikedCount() => _preferences.getInt(keyDailyLikedCount) ?? 0;

  @override
  Future<void> setDailyLikedCount(int count) async {
    await _preferences.setInt(keyDailyLikedCount, count);
  }
}

enum ConflictAction {
  abort,
  replace,
}
