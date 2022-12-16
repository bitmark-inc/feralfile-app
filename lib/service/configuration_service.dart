//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setIAPReceipt(String? value);

  String? getIAPReceipt();

  Future<void> setIAPJWT(JWT? value);

  JWT? getIAPJWT();

  Future<void> setTVConnectData(WCPeerMeta peerMeta, int id);

  Future<void> deleteTVConnectData();

  WCPeerMeta? getTVConnectPeerMeta();

  int? getTVConnectID();

  Future<void> setWCSessions(List<WCSessionStore> value);

  List<WCSessionStore> getWCSessions();

  Future<void> setDevicePasscodeEnabled(bool value);

  bool isDevicePasscodeEnabled();

  Future<void> setNotificationEnabled(bool value);

  bool? isNotificationEnabled();

  Future<void> setAnalyticEnabled(bool value);

  bool isAnalyticsEnabled();

  Future<void> setDoneOnboarding(bool value);

  bool isDoneOnboarding();

  Future<void> setPendingSettings(bool value);

  bool hasPendingSettings();

  bool shouldShowSubscriptionHint();

  Future setShouldShowSubscriptionHint(bool value);

  DateTime? getLastTimeAskForSubscription();

  Future setLastTimeAskForSubscription(DateTime date);

  Future<void> setDoneOnboardingOnce(bool value);

  bool isDoneOnboardingOnce();

  Future<void> setFullscreenIntroEnable(bool value);

  bool isFullscreenIntroEnabled();

  Future<void> setHidePersonaInGallery(
      List<String> personaUUIDs, bool isEnabled,
      {bool override = false});

  List<String> getPersonaUUIDsHiddenInGallery();

  bool isPersonaHiddenInGallery(String value);

  Future<void> setHideLinkedAccountInGallery(
      List<String> address, bool isEnabled,
      {bool override = false});

  List<String> getLinkedAccountsHiddenInGallery();

  bool isLinkedAccountHiddenInGallery(String value);

  List<String> getTempStorageHiddenTokenIDs({Network? network});

  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false});

  List<SentArtwork> getRecentlySentToken();

  Future updateRecentlySentToken(List<SentArtwork> sentArtwork,
      {bool override = false});

  Future<void> setWCDappSession(String? value);

  String? getWCDappSession();

  Future<void> setWCDappAccounts(List<String>? value);

  List<String>? getWCDappAccounts();

  DateTime? getLatestRefreshTokens();

  Future<bool> setLatestRefreshTokens(DateTime? value);

  Future<void> setReadReleaseNotesInVersion(String version);

  String? getReadReleaseNotesVersion();

  String? getPreviousBuildNumber();

  Future<void> setPreviousBuildNumber(String value);

  List<PlayListModel>? getPlayList();

  Future<void> setPlayList(List<PlayListModel>? value, {bool override = false});

  List<String> getFinishedSurveys();

  Future<void> setFinishedSurvey(List<String> surveyNames);

  Future<String> getAccountHMACSecret();

  bool isFinishedFeedOnBoarding();

  Future<void> setFinishedFeedOnBoarding(bool value);

  String? lastRemindReviewDate();

  Future<void> setLastRemindReviewDate(String? value);

  int? countOpenApp();

  Future<void> setCountOpenApp(int? value);

  // Feed
  Future<void> setLastTimeOpenFeed(int timestamp);

  int getLastTimeOpenFeed();

  Future<void> setHasFeed(bool value);

  bool hasFeed();

  // ----- App Setting -----
  bool isDemoArtworksMode();

  Future<bool> toggleDemoArtworksMode();

  bool showTokenDebugInfo();

  Future setShowTokenDebugInfo(bool show);

  // Do at once

  /// to determine a hash value of the current addresses where
  /// the app checked for Tezos artworks
  int? sentTezosArtworkMetricValue();

  Future setSentTezosArtworkMetric(int hashedAddresses);

  // Reload
  Future<void> reload();

  Future<void> removeAll();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_IAP_RECEIPT = "key_iap_receipt";
  static const String KEY_IAP_JWT = "key_iap_jwt";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";
  static const String KEY_DEVICE_PASSCODE = "device_passcode";
  static const String KEY_NOTIFICATION = "notifications";
  static const String KEY_ANALYTICS = "analytics";
  static const String KEY_FULLSCREEN_INTRO = "fullscreen_intro";
  static const String KEY_DONE_ONBOARING = "done_onboarding";
  static const String KEY_PENDING_SETTINGS = "has_pending_settings";
  static const String KEY_SHOULD_SHOW_SUBSCRIPTION_HINT =
      "should_show_subscription_hint";
  static const String KEY_LAST_TIME_ASK_SUBSCRIPTION =
      "last_time_ask_subscription";
  static const String KEY_DONE_ONBOARING_ONCE = "done_onboarding_once";
  static const String KEY_HIDDEN_PERSONAS_IN_GALLERY =
      'hidden_personas_in_gallery';
  static const String KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY =
      'hidden_linked_accounts_in_gallery';
  static const String KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS =
      'temp_storage_hidden_token_ids_mainnet';
  static const String KEY_RECENTLY_SENT_TOKEN = 'recently_sent_token_mainnet';
  static const String KEY_READ_RELEASE_NOTES_VERSION =
      'read_release_notes_version';
  static const String KEY_FINISHED_SURVEYS = "finished_surveys";
  static const String ACCOUNT_HMAC_SECRET = "account_hmac_secret";
  static const String KEY_FINISHED_FEED_ONBOARDING = "finished_feed_onboarding";

  // keys for WalletConnect dapp side
  static const String KEY_WC_DAPP_SESSION = "wc_dapp_store";
  static const String KEY_WC_DAPP_ACCOUNTS = "wc_dapp_accounts";

  // ----- App Setting -----
  static const String KEY_APP_SETTING_DEMO_ARTWORKS =
      "show_demo_artworks_preference";
  static const String KEY_LASTEST_REFRESH_TOKENS =
      "latest_refresh_tokens_mainnet_1";
  static const String KEY_PREVIOUS_BUILD_NUMBER = "previous_build_number";
  static const String KEY_SHOW_TOKEN_DEBUG_INFO = "show_token_debug_info";
  static const String LAST_REMIND_REVIEW = "last_remind_review";
  static const String COUNT_OPEN_APP = "count_open_app";
  static const String KEY_LAST_TIME_OPEN_FEED = "last_time_open_feed";

  static const String TV_CONNECT_PEER_META = "tv_connect_peer_meta";
  static const String TV_CONNECT_ID = "tv_connect_id";

  static const String PLAYLISTS = "playlists";
  static const String HAVE_FEED = "have_feed";

  // Do at once
  static const String KEY_SENT_TEZOS_ARTWORK_METRIC =
      "sent_tezos_artwork_metric";

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
  String? getIAPReceipt() {
    return _preferences.getString(KEY_IAP_RECEIPT);
  }

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
  Future<void> setTVConnectData(WCPeerMeta peerMeta, int id) async {
    final json = jsonEncode(peerMeta);
    await _preferences.setString(TV_CONNECT_PEER_META, json);
    await _preferences.setInt(TV_CONNECT_ID, id);
  }

  @override
  Future<void> deleteTVConnectData() async {
    await _preferences.remove(TV_CONNECT_PEER_META);
    await _preferences.remove(TV_CONNECT_ID);
  }

  @override
  WCPeerMeta? getTVConnectPeerMeta() {
    final data = _preferences.getString(TV_CONNECT_PEER_META);
    if (data == null) {
      return null;
    } else {
      final json = jsonDecode(data);
      return WCPeerMeta.fromJson(json);
    }
  }

  @override
  int? getTVConnectID() {
    return _preferences.getInt(TV_CONNECT_ID);
  }

  @override
  Future<void> setWCSessions(List<WCSessionStore> value) async {
    log.info("setWCSessions: $value");
    final json = jsonEncode(value);
    await _preferences.setString(KEY_WC_SESSIONS, json);
  }

  @override
  List<WCSessionStore> getWCSessions() {
    final json = _preferences.getString(KEY_WC_SESSIONS);
    final sessions = json != null ? jsonDecode(json) : List.empty();
    return List.from(sessions)
        .map((e) => WCSessionStore.fromJson(e))
        .toList(growable: false);
  }

  @override
  bool isDevicePasscodeEnabled() {
    return _preferences.getBool(KEY_DEVICE_PASSCODE) ?? false;
  }

  @override
  Future<void> setDevicePasscodeEnabled(bool value) async {
    log.info("setDevicePasscodeEnabled: $value");
    await _preferences.setBool(KEY_DEVICE_PASSCODE, value);
  }

  @override
  bool isAnalyticsEnabled() {
    return _preferences.getBool(KEY_ANALYTICS) ?? true;
  }

  @override
  bool? isNotificationEnabled() {
    return _preferences.getBool(KEY_NOTIFICATION);
  }

  @override
  bool isDoneOnboarding() {
    return _preferences.getBool(KEY_DONE_ONBOARING) ?? false;
  }

  @override
  bool hasPendingSettings() {
    return _preferences.getBool(KEY_PENDING_SETTINGS) ?? false;
  }

  @override
  Future<void> setPendingSettings(bool value) async {
    await _preferences.setBool(KEY_PENDING_SETTINGS, value);
  }

  @override
  bool isDoneOnboardingOnce() {
    return _preferences.getBool(KEY_DONE_ONBOARING_ONCE) ?? false;
  }

  @override
  Future<void> setAnalyticEnabled(bool value) async {
    log.info("setAnalyticEnabled: $value");
    await _preferences.setBool(KEY_ANALYTICS, value);
  }

  @override
  Future<void> setDoneOnboarding(bool value) async {
    log.info("setDoneOnboarding: $value");
    await _preferences.setBool(KEY_DONE_ONBOARING, value);
  }

  @override
  Future<void> setDoneOnboardingOnce(bool value) async {
    log.info("setDoneOnboardingOnce: $value");
    await _preferences.setBool(KEY_DONE_ONBOARING_ONCE, value);
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    log.info("setNotificationEnabled: $value");
    await _preferences.setBool(KEY_NOTIFICATION, value);
  }

  @override
  bool isFullscreenIntroEnabled() {
    return _preferences.getBool(KEY_FULLSCREEN_INTRO) ?? true;
  }

  @override
  Future<void> setFullscreenIntroEnable(bool value) async {
    log.info("setFullscreenIntroEnable: $value");
    await _preferences.setBool(KEY_FULLSCREEN_INTRO, value);
  }

  @override
  Future<void> setHidePersonaInGallery(
      List<String> personaUUIDs, bool isEnabled,
      {bool override = false}) async {
    if (override && isEnabled) {
      await _preferences.setStringList(
          KEY_HIDDEN_PERSONAS_IN_GALLERY, personaUUIDs);
    } else {
      var currentPersonaUUIDs =
          _preferences.getStringList(KEY_HIDDEN_PERSONAS_IN_GALLERY) ?? [];

      isEnabled
          ? currentPersonaUUIDs.addAll(personaUUIDs)
          : currentPersonaUUIDs.removeWhere((i) => personaUUIDs.contains(i));
      await _preferences.setStringList(
          KEY_HIDDEN_PERSONAS_IN_GALLERY, currentPersonaUUIDs);
    }
  }

  @override
  List<String> getPersonaUUIDsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_PERSONAS_IN_GALLERY) ?? [];
  }

  @override
  bool isPersonaHiddenInGallery(String value) {
    var personaUUIDs = getPersonaUUIDsHiddenInGallery();
    return personaUUIDs.contains(value);
  }

  @override
  Future<void> setHideLinkedAccountInGallery(
      List<String> addresses, bool isEnabled,
      {bool override = false}) async {
    if (override && isEnabled) {
      await _preferences.setStringList(
          KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY, addresses);
    } else {
      var linkedAccounts =
          _preferences.getStringList(KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY) ??
              [];

      isEnabled
          ? linkedAccounts.addAll(addresses)
          : linkedAccounts.removeWhere((i) => addresses.contains(i));
      await _preferences.setStringList(
          KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY, linkedAccounts);
    }
  }

  @override
  List<String> getLinkedAccountsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY) ??
        [];
  }

  @override
  bool isLinkedAccountHiddenInGallery(String value) {
    var hiddenLinkedAccounts = getLinkedAccountsHiddenInGallery();
    return hiddenLinkedAccounts.contains(value);
  }

  @override
  List<String> getTempStorageHiddenTokenIDs({Network? network}) {
    return _preferences.getStringList(KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS) ?? [];
  }

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
    _removeExpiredSentToken(DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME));
    final updateTokens =
        sentArtwork.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updateTokens);
    } else {
      var sentTokenIDs = _preferences.getStringList(key) ?? [];

      sentTokenIDs.addAll(updateTokens);
      await _preferences.setStringList(key, sentTokenIDs.toSet().toList());
    }
  }

  Future _removeExpiredSentToken(DateTime timestampExpired) async {
    List<SentArtwork> token = getRecentlySentToken();
    token
        .removeWhere((element) => element.timestamp.isBefore(timestampExpired));
    await _preferences.setStringList(KEY_RECENTLY_SENT_TOKEN,
        token.map((e) => jsonEncode(e.toJson())).toList());
  }

  @override
  Future<void> setWCDappSession(String? value) async {
    log.info("setWCDappSession: $value");
    if (value != null) {
      await _preferences.setString(KEY_WC_DAPP_SESSION, value);
    } else {
      await _preferences.remove(KEY_WC_DAPP_SESSION);
    }
  }

  @override
  String? getWCDappSession() {
    return _preferences.getString(KEY_WC_DAPP_SESSION);
  }

  @override
  Future<void> setWCDappAccounts(List<String>? value) async {
    log.info("setWCDappAccounts: $value");
    if (value != null) {
      await _preferences.setStringList(KEY_WC_DAPP_ACCOUNTS, value);
    } else {
      await _preferences.remove(KEY_WC_DAPP_ACCOUNTS);
    }
  }

  @override
  List<String>? getWCDappAccounts() {
    return _preferences.getStringList(KEY_WC_DAPP_ACCOUNTS);
  }

  @override
  Future<void> setReadReleaseNotesInVersion(String version) async {
    await _preferences.setString(KEY_READ_RELEASE_NOTES_VERSION, version);
  }

  @override
  String? getReadReleaseNotesVersion() {
    return _preferences.getString(KEY_READ_RELEASE_NOTES_VERSION);
  }

  @override
  Future<void> setLastTimeOpenFeed(int timestamp) async {
    await _preferences.setInt(KEY_LAST_TIME_OPEN_FEED, timestamp);
  }

  @override
  int getLastTimeOpenFeed() {
    return _preferences.getInt(KEY_LAST_TIME_OPEN_FEED) ?? 0;
  }

  @override
  bool shouldShowSubscriptionHint() {
    return _preferences.getBool(KEY_SHOULD_SHOW_SUBSCRIPTION_HINT) ?? true;
  }

  @override
  Future setShouldShowSubscriptionHint(bool value) async {
    await _preferences.setBool(KEY_SHOULD_SHOW_SUBSCRIPTION_HINT, value);
  }

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
  bool isDemoArtworksMode() {
    return _preferences.getBool(KEY_APP_SETTING_DEMO_ARTWORKS) ?? false;
  }

  @override
  Future<bool> toggleDemoArtworksMode() async {
    final newValue = !isDemoArtworksMode();
    await _preferences.setBool(KEY_APP_SETTING_DEMO_ARTWORKS, newValue);
    return newValue;
  }

  @override
  Future<void> reload() {
    return _preferences.reload();
  }

  @override
  DateTime? getLatestRefreshTokens() {
    const key = KEY_LASTEST_REFRESH_TOKENS;
    final time = _preferences.getInt(key);

    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  @override
  Future<bool> setLatestRefreshTokens(DateTime? value) {
    const key = KEY_LASTEST_REFRESH_TOKENS;

    if (value == null) {
      return _preferences.remove(key);
    }

    return _preferences.setInt(key, value.millisecondsSinceEpoch);
  }

  @override
  Future<void> setPreviousBuildNumber(String value) async {
    await _preferences.setString(KEY_PREVIOUS_BUILD_NUMBER, value);
  }

  @override
  String? getPreviousBuildNumber() {
    return _preferences.getString(KEY_PREVIOUS_BUILD_NUMBER);
  }

  @override
  List<String> getFinishedSurveys() {
    return _preferences.getStringList(KEY_FINISHED_SURVEYS) ?? [];
  }

  @override
  Future<void> setFinishedSurvey(List<String> surveyNames) {
    var finishedSurveys = getFinishedSurveys();
    finishedSurveys.addAll(surveyNames);
    return _preferences.setStringList(
        KEY_FINISHED_SURVEYS, finishedSurveys.toSet().toList());
  }

  @override
  bool isFinishedFeedOnBoarding() {
    return _preferences.getBool(KEY_FINISHED_FEED_ONBOARDING) ?? false;
  }

  @override
  Future<void> setFinishedFeedOnBoarding(bool value) async {
    await _preferences.setBool(KEY_FINISHED_FEED_ONBOARDING, value);
  }

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
  bool showTokenDebugInfo() {
    return _preferences.getBool(KEY_SHOW_TOKEN_DEBUG_INFO) ?? false;
  }

  @override
  Future setShowTokenDebugInfo(bool show) async {
    await _preferences.setBool(KEY_SHOW_TOKEN_DEBUG_INFO, show);
  }

  @override
  Future<void> removeAll() {
    return _preferences.clear();
  }

  @override
  int? sentTezosArtworkMetricValue() {
    return _preferences.getInt(KEY_SENT_TEZOS_ARTWORK_METRIC);
  }

  @override
  Future setSentTezosArtworkMetric(int hashedAddresses) {
    return _preferences.setInt(KEY_SENT_TEZOS_ARTWORK_METRIC, hashedAddresses);
  }

  @override
  String? lastRemindReviewDate() {
    return _preferences.getString(LAST_REMIND_REVIEW);
  }

  @override
  Future<void> setLastRemindReviewDate(String? value) async {
    if (value == null) {
      await _preferences.remove(LAST_REMIND_REVIEW);
      return;
    }
    await _preferences.setString(LAST_REMIND_REVIEW, value);
  }

  @override
  int? countOpenApp() {
    return _preferences.getInt(COUNT_OPEN_APP);
  }

  @override
  Future<void> setCountOpenApp(int? value) async {
    if (value == null) {
      await _preferences.remove(COUNT_OPEN_APP);
      return;
    }
    await _preferences.setInt(COUNT_OPEN_APP, value);
  }

  @override
  List<PlayListModel>? getPlayList() {
    final playListsString = _preferences.getStringList(PLAYLISTS) ?? [];
    return playListsString
        .map((e) => PlayListModel.fromJson(jsonDecode(e)))
        .toList();
  }

  @override
  Future<void> setPlayList(List<PlayListModel>? value,
      {bool override = false}) async {
    final playlists = value?.map((e) => jsonEncode(e)).toList() ?? [];

    if (override) {
      await _preferences.setStringList(PLAYLISTS, playlists);
    } else {
      var playlistsSave = _preferences.getStringList(PLAYLISTS) ?? [];

      playlistsSave.addAll(playlists);
      await _preferences.setStringList(
          PLAYLISTS, playlistsSave.toSet().toList());
    }
  }

  @override
  Future<void> setHasFeed(bool value) async {
    await _preferences.setBool(HAVE_FEED, value);
  }

  @override
  bool hasFeed() {
    return _preferences.getBool(HAVE_FEED) ?? false;
  }
}
