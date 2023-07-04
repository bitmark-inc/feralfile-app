//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setAnnouncementLastPullTime(int lastPullTime);

  int? getAnnouncementLastPullTime();

  Future<void> setOldUser();

  bool getIsOldUser();

  Future<void> setIAPReceipt(String? value);

  String? getIAPReceipt();

  Future<void> setIAPJWT(JWT? value);

  JWT? getIAPJWT();

  Future<void> setPremium(bool value);

  bool isPremium();

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

  Future<void> readRemoveSupport(bool value);

  bool isReadRemoveSupport();

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

  List<PlayListModel> getPlayList();

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

  Future setLastTimeOpenEditorial(DateTime time);

  DateTime? getLastTimeOpenEditorial();

  // ----- App Setting -----
  bool isDemoArtworksMode();

  Future<bool> toggleDemoArtworksMode();

  bool showTokenDebugInfo();

  Future setShowTokenDebugInfo(bool show);

  bool isLastestVersion();

  Future setLastestVersion(bool value);

  Future setDoneOnboardingTime(DateTime time);

  DateTime? getDoneOnboardingTime();

  Future setSubscriptionTime(DateTime time);

  DateTime? getSubscriptionTime();

  Future setAlreadyShowNotifTip(bool show);

  Future setAlreadyShowProTip(bool show);

  Future setAlreadyShowTvAppTip(bool show);

  Future setAlreadyShowCreatePlaylistTip(bool show);

  Future setAlreadyShowLinkOrImportTip(bool show);

  bool getAlreadyShowNotifTip();

  bool getAlreadyShowProTip();

  bool getAlreadyShowTvAppTip();

  bool getAlreadyShowCreatePlaylistTip();

  bool getAlreadyShowLinkOrImportTip();

  DateTime? getShowBackupSettingTip();

  Future setShowBackupSettingTip(DateTime time);

  bool getShowWhatNewAddressTip(int currentVersion);

  Future setShowWhatNewAddressTipRead(int currentVersion);

  // Do at once

  /// to determine a hash value of the current addresses where
  /// the app checked for Tezos artworks
  int? sentTezosArtworkMetricValue();

  Future setSentTezosArtworkMetric(int hashedAddresses);

  bool allowContribution();

  Future<void> setAllowContribution(bool value);

  // Reload
  Future<void> reload();

  Future<void> removeAll();

  ValueNotifier<bool> get showNotifTip;

  ValueNotifier<bool> get showProTip;

  ValueNotifier<bool> get showTvAppTip;

  ValueNotifier<bool> get showCreatePlaylistTip;

  ValueNotifier<bool> get showLinkOrImportTip;

  ValueNotifier<bool> get showBackupSettingTip;

  ValueNotifier<bool> get showWhatNewAddressTip;

  ValueNotifier<List<SharedPostcard>> get expiredPostcardSharedLinkTip;

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

  Future<void> removeExpiredStampingPostcard();

  Future<void> setAutoShowPostcard(bool value);

  bool isAutoShowPostcard();

  List<PostcardIdentity> getListPostcardAlreadyShowYouDidIt();

  Future<void> setListPostcardAlreadyShowYouDidIt(List<PostcardIdentity> value,
      {bool override = false});

  Future<void> setMixpanelConfig(MixpanelConfig config);

  MixpanelConfig? getMixpanelConfig();

  Future<void> setAlreadyShowPostcardUpdates(List<PostcardIdentity> value,
      {bool override = false});

  List<PostcardIdentity> getAlreadyShowPostcardUpdates();

  String getVersionInfo();

  Future<void> setVersionInfo(String version);
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_IAP_RECEIPT = "key_iap_receipt";
  static const String KEY_IAP_JWT = "key_iap_jwt";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";
  static const String IS_PREMIUM = "is_premium";
  static const String KEY_DEVICE_PASSCODE = "device_passcode";
  static const String KEY_NOTIFICATION = "notifications";
  static const String KEY_ANALYTICS = "analytics";
  static const String KEY_FULLSCREEN_INTRO = "fullscreen_intro";
  static const String KEY_DONE_ONBOARING = "done_onboarding";
  static const String KEY_PENDING_SETTINGS = "has_pending_settings";
  static const String READ_REMOVE_SUPPORT = "read_remove_support";
  static const String KEY_SHOULD_SHOW_SUBSCRIPTION_HINT =
      "should_show_subscription_hint";
  static const String KEY_LAST_TIME_ASK_SUBSCRIPTION =
      "last_time_ask_subscription";
  static const String KEY_DONE_ONBOARING_ONCE = "done_onboarding_once";
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
  static const String KEY_SHARED_POSTCARD = "shared_postcard";

  static const String ANNOUNCEMENT_LAST_PULL_TIME =
      "announcement_last_pull_time";
  static const String OLD_USER = "old_user";

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
  static const String KEY_LAST_TIME_OPEN_EDITORIAL = "last_time_open_editorial";

  static const String TV_CONNECT_PEER_META = "tv_connect_peer_meta";
  static const String TV_CONNECT_ID = "tv_connect_id";

  static const String PLAYLISTS = "playlists";
  static const String HAVE_FEED = "have_feed";
  static const String KEY_LASTEST_VERSION = "lastest_version";

  static const String ALLOW_CONTRIBUTION = "allow_contribution";

  static const String SHOW_AU_CHAIN_INFO = "show_au_chain_info";

  static const String KEY_DONE_ON_BOARDING_TIME = "done_on_boarding_time";

  static const String KEY_SUBSCRIPTION_TIME = "subscription_time";

  static const String KEY_CAN_SHOW_NOTIF_TIP = "show_notif_tip";

  static const String KEY_CAN_SHOW_PRO_TIP = "show_pro_tip";

  static const String KEY_CAN_SHOW_TV_APP_TIP = "show_tv_app_tip";

  static const String KEY_CAN_SHOW_CREATE_PLAYLIST_TIP =
      "show_create_playlist_tip";

  static const String KEY_CAN_SHOW_LINK_OR_IMPORT_TIP =
      "show_link_or_import_tip";

  static const String KEY_SHOW_BACK_UP_SETTINGS_TIP =
      "show_back_up_settings_tip";

  static const String KEY_SHOW_WHAT_NEW_ADDRESS_TIP =
      "show_what_new_address_tip";

  static const String KEY_STAMPING_POSTCARD = "stamping_postcard";

  static const String KEY_AUTO_SHOW_POSTCARD = "auto_show_postcard";

  static const String KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD =
      "already_show_you_did_it_postcard";

  static const String KEY_CURRENT_GROUP_CHAT_ID = "current_group_chat_id";

  static const String KEY_ALREADY_SHOW_POSTCARD_UPDATES =
      "already_show_postcard_updates";

  static const String KEY_MIXPANEL_PROPS = "mixpanel_props";

  static const String KEY_PACKAGE_INFO = "package_info";

  final ValueNotifier<List<SharedPostcard>> _expiredPostcardSharedLinkTip =
      ValueNotifier([]);

  @override
  Future setAlreadyShowNotifTip(bool show) async {
    await _preferences.setBool(KEY_CAN_SHOW_NOTIF_TIP, show);
  }

  @override
  Future setAlreadyShowProTip(bool show) async {
    await _preferences.setBool(KEY_CAN_SHOW_PRO_TIP, show);
  }

  @override
  Future setAlreadyShowTvAppTip(bool show) async {
    await _preferences.setBool(KEY_CAN_SHOW_TV_APP_TIP, show);
  }

  @override
  Future setAlreadyShowCreatePlaylistTip(bool show) async {
    await _preferences.setBool(KEY_CAN_SHOW_CREATE_PLAYLIST_TIP, show);
  }

  @override
  Future setAlreadyShowLinkOrImportTip(bool show) async {
    await _preferences.setBool(KEY_CAN_SHOW_LINK_OR_IMPORT_TIP, show);
  }

  @override
  bool getAlreadyShowNotifTip() {
    return _preferences.getBool(KEY_CAN_SHOW_NOTIF_TIP) ?? false;
  }

  @override
  bool getAlreadyShowProTip() {
    return _preferences.getBool(KEY_CAN_SHOW_PRO_TIP) ?? false;
  }

  @override
  bool getAlreadyShowTvAppTip() {
    return _preferences.getBool(KEY_CAN_SHOW_TV_APP_TIP) ?? false;
  }

  @override
  bool getAlreadyShowCreatePlaylistTip() {
    return _preferences.getBool(KEY_CAN_SHOW_CREATE_PLAYLIST_TIP) ?? false;
  }

  @override
  bool getAlreadyShowLinkOrImportTip() {
    return _preferences.getBool(KEY_CAN_SHOW_LINK_OR_IMPORT_TIP) ?? false;
  }

  // Do at once
  static const String KEY_SENT_TEZOS_ARTWORK_METRIC =
      "sent_tezos_artwork_metric";

  static const String POSTCARD_MINT = "postcard_mint";

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
    final currentValue = isDoneOnboarding();
    await _preferences.setBool(KEY_DONE_ONBOARING, value);

    if (currentValue == false && value == true && getIsOldUser() == false) {
      await setDoneOnboardingTime(DateTime.now());
      await setOldUser();
      Future.delayed(const Duration(seconds: 2), () async {
        injector<CustomerSupportService>()
            .createAnnouncement(AnnouncementID.WELCOME);
      });
    }
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
  List<PlayListModel> getPlayList() {
    final playListsString = _preferences.getStringList(PLAYLISTS);
    if (playListsString == null || playListsString.isEmpty) {
      return [];
    }
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

  @override
  Future<void> setLastestVersion(bool value) async {
    await _preferences.setBool(KEY_LASTEST_VERSION, value);
  }

  @override
  bool isLastestVersion() {
    return _preferences.getBool(KEY_LASTEST_VERSION) ?? false;
  }

  @override
  bool allowContribution() {
    return _preferences.getBool(ALLOW_CONTRIBUTION) ?? true;
  }

  @override
  Future<void> setAllowContribution(bool value) async {
    await _preferences.setBool(ALLOW_CONTRIBUTION, value);
  }

  @override
  int? getAnnouncementLastPullTime() {
    return _preferences.getInt(ANNOUNCEMENT_LAST_PULL_TIME);
  }

  @override
  Future<void> setAnnouncementLastPullTime(int lastPullTime) async {
    await _preferences.setInt(ANNOUNCEMENT_LAST_PULL_TIME, lastPullTime);
  }

  @override
  bool getIsOldUser() {
    return _preferences.getBool(OLD_USER) ?? false;
  }

  @override
  Future<void> setOldUser() async {
    await _preferences.setBool(OLD_USER, true);
  }

  @override
  bool isPremium() {
    return _preferences.getBool(IS_PREMIUM) ?? false;
  }

  @override
  Future<void> setPremium(bool value) async {
    await _preferences.setBool(IS_PREMIUM, value);
  }

  @override
  bool isReadRemoveSupport() {
    return _preferences.getBool(READ_REMOVE_SUPPORT) ?? false;
  }

  @override
  Future<void> readRemoveSupport(bool value) async {
    await _preferences.setBool(READ_REMOVE_SUPPORT, value);
  }

  @override
  ValueNotifier<bool> showProTip = ValueNotifier(false);

  @override
  ValueNotifier<bool> showCreatePlaylistTip = ValueNotifier(false);

  @override
  ValueNotifier<bool> showLinkOrImportTip = ValueNotifier(false);

  @override
  ValueNotifier<bool> showNotifTip = ValueNotifier(false);

  @override
  ValueNotifier<bool> showTvAppTip = ValueNotifier(false);

  @override
  ValueNotifier<bool> showWhatNewAddressTip = ValueNotifier(false);

  @override
  DateTime? getDoneOnboardingTime() {
    final timeString = _preferences.getString(KEY_DONE_ON_BOARDING_TIME);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  @override
  Future setDoneOnboardingTime(DateTime time) async {
    await _preferences.setString(
        KEY_DONE_ON_BOARDING_TIME, time.toIso8601String());
  }

  @override
  DateTime? getSubscriptionTime() {
    final timeString = _preferences.getString(KEY_SUBSCRIPTION_TIME);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  @override
  Future setSubscriptionTime(DateTime time) async {
    await _preferences.setString(KEY_SUBSCRIPTION_TIME, time.toIso8601String());
  }

  @override
  DateTime? getShowBackupSettingTip() {
    final timeString = _preferences.getString(KEY_SHOW_BACK_UP_SETTINGS_TIP);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  @override
  Future setShowBackupSettingTip(DateTime time) async {
    await _preferences.setString(
        KEY_SHOW_BACK_UP_SETTINGS_TIP, time.toIso8601String());
  }

  @override
  ValueNotifier<bool> showBackupSettingTip = ValueNotifier(false);

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
      expiredPostcardSharedLinkTip.value =
          await sharedPostcards.expiredPostcards;
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
          .toList();
      uniqueSharedPostcard.sort((e1, e2) {
        if (e2.sharedAt == null || e1.sharedAt == null) {
          return 0;
        }
        return e2.sharedAt!.compareTo(e1.sharedAt!);
      });

      uniqueSharedPostcard.unique((element) => element.tokenID + element.owner);
      await _preferences.setStringList(key,
          uniqueSharedPostcard.map((e) => jsonEncode(e.toJson())).toList());
      expiredPostcardSharedLinkTip.value =
          await uniqueSharedPostcard.expiredPostcards;
    }
  }

  @override
  Future<void> removeSharedPostcardWhere(bool Function(SharedPostcard) test) {
    final sharedPostcardString =
        _preferences.getStringList(KEY_SHARED_POSTCARD) ?? [];
    final sharedPostcards = sharedPostcardString
        .map((e) => SharedPostcard.fromJson(jsonDecode(e)))
        .toSet()
        .toList();
    sharedPostcards.removeWhere(test);
    return updateSharedPostcard(sharedPostcards, override: true);
  }

  @override
  List<String> getListPostcardMint() {
    return _preferences.getStringList(POSTCARD_MINT) ?? [];
  }

  @override
  Future<void> setListPostcardMint(List<String> tokenID,
      {bool override = false, bool isRemoved = false}) async {
    if (override) {
      await _preferences.setStringList(POSTCARD_MINT, tokenID);
    } else {
      var currentPortcardMints =
          _preferences.getStringList(POSTCARD_MINT) ?? [];
      if (isRemoved) {
        currentPortcardMints
            .removeWhere((element) => tokenID.contains(element));
      } else {
        currentPortcardMints.addAll(tokenID);
      }
      await _preferences.setStringList(POSTCARD_MINT, currentPortcardMints);
    }
  }

  @override
  List<StampingPostcard> getStampingPostcard() {
    return _preferences
            .getStringList(KEY_STAMPING_POSTCARD)
            ?.map((e) => StampingPostcard.fromJson(jsonDecode(e)))
            .toList()
            .where((element) => element.timestamp
                .isAfter(DateTime.now().subtract(STAMPING_POSTCARD_LIMIT_TIME)))
            .toList() ??
        [];
  }

  @override
  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false}) async {
    const key = KEY_STAMPING_POSTCARD;
    final updatePostcards = values.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updatePostcards);
    } else {
      await removeExpiredStampingPostcard();
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
  Future<void> removeExpiredStampingPostcard() async {
    final currentStampingPostcard = getStampingPostcard();
    final now = DateTime.now();
    final unexpiredStampingPostcard = currentStampingPostcard
        .where((element) => element.timestamp
            .isAfter(now.subtract(STAMPING_POSTCARD_LIMIT_TIME)))
        .toList();
    _preferences.setStringList(KEY_STAMPING_POSTCARD,
        unexpiredStampingPostcard.map((e) => jsonEncode(e.toJson())).toList());
  }

  @override
  bool isAutoShowPostcard() {
    return _preferences.getBool(KEY_AUTO_SHOW_POSTCARD) ?? false;
  }

  @override
  Future<void> setAutoShowPostcard(bool value) async {
    log.info('setAutoShowPostcard: $value');
    await _preferences.setBool(KEY_AUTO_SHOW_POSTCARD, value);
  }

  @override
  List<PostcardIdentity> getListPostcardAlreadyShowYouDidIt() {
    return _preferences
            .getStringList(KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD)
            ?.map((e) => PostcardIdentity.fromJson(jsonDecode(e)))
            .toList() ??
        [];
  }

  @override
  Future<void> setListPostcardAlreadyShowYouDidIt(List<PostcardIdentity> values,
      {bool override = false}) async {
    const key = KEY_ALREADY_SHOW_YOU_DID_IT_POSTCARD;
    final updateValues = values.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      await _preferences.setStringList(key, updateValues);
    } else {
      var currentValue = _preferences.getStringList(key) ?? [];

      currentValue.addAll(updateValues);
      await _preferences.setStringList(key, currentValue.toSet().toList());
    }
  }

  @override
  DateTime? getLastTimeOpenEditorial() {
    final timeString = _preferences.getString(KEY_LAST_TIME_OPEN_EDITORIAL);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  @override
  Future setLastTimeOpenEditorial(DateTime time) {
    return _preferences.setString(
        KEY_LAST_TIME_OPEN_EDITORIAL, time.toIso8601String());
  }

  @override
  MixpanelConfig? getMixpanelConfig() {
    final data = _preferences.getString(KEY_MIXPANEL_PROPS);
    if (data == null) {
      return null;
    }
    final config = MixpanelConfig.fromJson(jsonDecode(data));
    return config;
  }

  @override
  Future<void> setMixpanelConfig(MixpanelConfig config) async {
    await _preferences.setString(
        KEY_MIXPANEL_PROPS, jsonEncode(config.toJson()));
  }

  @override
  List<PostcardIdentity> getAlreadyShowPostcardUpdates() {
    return _preferences
            .getStringList(KEY_ALREADY_SHOW_POSTCARD_UPDATES)
            ?.map((e) => PostcardIdentity.fromJson(jsonDecode(e)))
            .toList() ??
        [];
  }

  @override
  Future<void> setAlreadyShowPostcardUpdates(List<PostcardIdentity> value,
      {bool override = false}) {
    const key = KEY_ALREADY_SHOW_POSTCARD_UPDATES;
    final updateValues = value.map((e) => jsonEncode(e.toJson())).toList();

    if (override) {
      return _preferences.setStringList(key, updateValues);
    } else {
      var currentValue = _preferences.getStringList(key) ?? [];

      currentValue.addAll(updateValues);
      return _preferences.setStringList(key, currentValue.toSet().toList());
    }
  }

  @override
  String getVersionInfo() {
    return _preferences.getString(KEY_PACKAGE_INFO) ?? "";
  }

  @override
  Future<void> setVersionInfo(String version) async {
    await _preferences.setString(KEY_PACKAGE_INFO, version);
  }

  @override
  bool getShowWhatNewAddressTip(int currentVersion) {
    final latestReadVersion =
        _preferences.getInt(KEY_SHOW_WHAT_NEW_ADDRESS_TIP) ?? 0;
    return latestReadVersion < currentVersion;
  }

  @override
  Future setShowWhatNewAddressTipRead(int currentVersion) async {
    await _preferences.setInt(KEY_SHOW_WHAT_NEW_ADDRESS_TIP, currentVersion);
  }

  @override
  ValueNotifier<List<SharedPostcard>> get expiredPostcardSharedLinkTip =>
      _expiredPostcardSharedLinkTip;
}
