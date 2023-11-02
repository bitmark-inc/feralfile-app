//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/dao/announcement_dao.dart';
import 'package:autonomy_flutter/database/dao/draft_customer_support_dao.dart';
import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/gateway/announcement_api.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'metric_client_service.dart';

class CustomerSupportUpdate {
  DraftCustomerSupport draft;
  PostedMessageResponse response;

  CustomerSupportUpdate({
    required this.draft,
    required this.response,
  });
}

abstract class CustomerSupportService {
  ValueNotifier<List<int>?>
      get numberOfIssuesInfo; // [numberOfIssues, numberOfUnreadIssues]
  ValueNotifier<int> get triggerReloadMessages;

  ValueNotifier<CustomerSupportUpdate?> get customerSupportUpdate;

  Map<String, String> get tempIssueIDMap;

  List<String>? get errorMessages;

  Future<IssueDetails> getDetails(String issueID);

  Future<List<Issue>> getIssues();

  Future<List<ChatThread>> getIssuesAndAnnouncement();

  Future draftMessage(DraftCustomerSupport draft);

  Future processMessages();

  Future<List<DraftCustomerSupport>> getDrafts(String issueID);

  Future<String> getStoredDirectory();

  Future<String> storeFile(String filename, List<int> bytes);

  Future reopen(String issueID);

  Future rateIssue(String issueID, int rating);

  Future<void> removeErrorMessage(String uuid, {bool isDelete = false});

  void sendMessageFail(String uuid);

  Future<void> markAnnouncementAsRead(String announcementID);

  Future<void> fetchAnnouncement();

  Future<void> createAnnouncement(AnnouncementID type);

  Future<AnnouncementLocal?> findAnnouncementFromIssueId(String issueId);

  Future<AnnouncementLocal?> findAnnouncement(String announcementID);
}

class CustomerSupportServiceImpl extends CustomerSupportService {
// 1 day.

  final DraftCustomerSupportDao _draftCustomerSupportDao;
  final CustomerSupportApi _customerSupportApi;
  final ConfigurationService _configurationService;
  final AnnouncementLocalDao _announcementDao;
  final AnnouncementApi _announcementApi;

  @override
  List<String> errorMessages = [];
  int retryTime = 0;

  @override
  ValueNotifier<List<int>?> numberOfIssuesInfo = ValueNotifier(null);
  @override
  ValueNotifier<int> triggerReloadMessages = ValueNotifier(0);
  @override
  ValueNotifier<CustomerSupportUpdate?> customerSupportUpdate =
      ValueNotifier(null);
  @override
  Map<String, String> tempIssueIDMap = {};

  CustomerSupportServiceImpl(
      this._draftCustomerSupportDao,
      this._customerSupportApi,
      this._configurationService,
      this._announcementDao,
      this._announcementApi);

  bool _isProcessingDraftMessages = false;

  @override
  Future<List<Issue>> getIssues() async {
    final issues = await _customerSupportApi.getIssues();
    issues.removeWhere(
        (element) => element.tags.contains(ReportIssueType.ReportNFTIssue));
    final drafts = await _draftCustomerSupportDao.getAllDrafts();
    drafts.removeWhere(
        (element) => element.reportIssueType == ReportIssueType.ReportNFTIssue);

    for (var draft in drafts) {
      if (draft.type != CSMessageType.CreateIssue.rawValue) continue;

      final draftData = draft.draftData;

      var issueTitle = draftData.title ?? draftData.text;
      if (issueTitle == null || issueTitle.isEmpty) {
        issueTitle = draftData.attachments?.first.fileName ?? 'Unnamed';
      }

      final draftIssue = Issue(
        issueID: draft.issueID,
        status: 'open',
        title: issueTitle,
        tags: [draft.reportIssueType],
        timestamp: draft.createdAt,
        total: 1,
        unread: 0,
        lastMessage: null,
        draft: draft,
        rating: draft.rating,
        announcementID: draftData.announcementId,
      );
      issues.add(draftIssue);
    }

    for (var issue in issues) {
      try {
        final latestDraft = drafts.firstWhere((element) =>
            element.issueID == issue.issueID &&
            element.type != CSMessageType.CreateIssue.rawValue);

        issue.draft = latestDraft;
      } catch (_) {
        continue;
      }
    }

    return issues;
  }

  @override
  Future<IssueDetails> getDetails(String issueID) async {
    return await _customerSupportApi.getDetails(issueID);
  }

  @override
  Future draftMessage(DraftCustomerSupport draft) async {
    await _draftCustomerSupportDao.insertDraft(draft);
    processMessages();
  }

  @override
  Future<void> removeErrorMessage(String uuid, {bool isDelete = false}) async {
    retryTime = 0;
    final id = uuid.substring(0, 36);
    errorMessages.remove(id);
    if (isDelete) {
      var msg = await _draftCustomerSupportDao.getDraft(id);
      if (msg != null) {
        await _draftCustomerSupportDao.deleteDraft(msg);
        if (msg.draftData.attachments != null &&
            msg.draftData.attachments!.isNotEmpty) {
          var draftData = msg.draftData;
          String name = uuid.substring(36);
          final fileToRemove = draftData.attachments!
              .firstWhereOrNull((element) => element.fileName.contains(name));
          if (draftData.attachments!.remove(fileToRemove)) {
            msg.data = jsonEncode(draftData);
            await _draftCustomerSupportDao.insertDraft(msg);
            errorMessages.add(id);
          }
          if (msg.type == CSMessageType.PostLogs.rawValue &&
              fileToRemove != null) {
            File file = File(fileToRemove.path);
            file.delete();
          }
        }
      }
    }
  }

  @override
  void sendMessageFail(String uuid) {
    if (retryTime > 5) {
      errorMessages.add(uuid);
      retryTime = 0;
    }
  }

  @override
  Future processMessages() async {
    log.info('[CS-Service][trigger] processMessages');
    if (_isProcessingDraftMessages) return;
    final fetchLimit = errorMessages.length + 1;
    log.info('[CS-Service][start] processMessages');
    final draftMsgsRaw = await _draftCustomerSupportDao.fetchDrafts(fetchLimit);
    if (draftMsgsRaw.isEmpty) return;
    final draftMsg = draftMsgsRaw
        .firstWhereOrNull((element) => !errorMessages.contains(element.uuid));
    if (draftMsg == null) return;
    log.info('[CS-Service][start] processMessages hasDraft');
    _isProcessingDraftMessages = true;

    retryTime++;

    // Edge Case when database has not updated the new issueID for new comments
    if (draftMsg.type != 'CreateIssue' && draftMsg.issueID.contains("TEMP")) {
      final newIssueID = tempIssueIDMap[draftMsg.issueID];
      if (newIssueID != null) {
        await _draftCustomerSupportDao.updateIssueID(
            draftMsg.issueID, newIssueID);
      } else {
        if (!draftMsgsRaw.any((element) =>
            ((element.issueID == draftMsg.issueID) &&
                (element.uuid != draftMsg.uuid)))) {
          await _draftCustomerSupportDao.deleteDraft(draftMsg);
        } else {
          sendMessageFail(draftMsg.uuid);
        }
      }

      _isProcessingDraftMessages = false;
      processMessages();
      return;
    }

    // Parse data
    final data = DraftCustomerSupportData.fromJson(jsonDecode(draftMsg.data));
    List<SendAttachment>? sendAttachments;

    try {
      if (data.attachments != null) {
        sendAttachments =
            await Future.wait(data.attachments!.map((element) async {
          File file = File(element.path);
          final bytes = await file.readAsBytes();
          return SendAttachment(
            data: base64Encode(bytes),
            title: element.fileName,
          );
        }));
      }
    } on FileSystemException catch (exception) {
      log.info('[CS-Service] can not find file in draftCustomerSupport');
      Sentry.captureException(exception);

      // just delete draft because we can not do anything more
      await _draftCustomerSupportDao.deleteDraft(draftMsg);
      removeErrorMessage(draftMsg.uuid);
      _isProcessingDraftMessages = false;
      log.info(
          '[CS-Service][end] processMessages delete invalid draftMesssage');
      processMessages();
      return;
    }

    try {
      switch (draftMsg.type) {
        case 'CreateIssue':
          final result = await createIssue(
            draftMsg.reportIssueType,
            data.text,
            sendAttachments,
            title: data.title,
            mutedText: draftMsg.mutedMessages.split("[SEPARATOR]"),
            announcementID: data.announcementId,
          );
          tempIssueIDMap[draftMsg.issueID] = result.issueID;
          await _draftCustomerSupportDao.deleteDraft(draftMsg);
          await _draftCustomerSupportDao.updateIssueID(
              draftMsg.issueID, result.issueID);
          customerSupportUpdate.value =
              CustomerSupportUpdate(draft: draftMsg, response: result);

          break;

        default:
          final result =
              await commentIssue(draftMsg.issueID, data.text, sendAttachments);
          await _draftCustomerSupportDao.deleteDraft(draftMsg);
          customerSupportUpdate.value =
              CustomerSupportUpdate(draft: draftMsg, response: result);
          break;
      }

      // Delete logs attachment so it doesn't waste device's storage
      if (draftMsg.type == CSMessageType.PostLogs.rawValue &&
          data.attachments != null) {
        log.info('[CS-Service][start] processMessages delete temp logs file');
        await Future.wait(data.attachments!.map((element) async {
          File file = File(element.path);
          file.delete();
        }));
      }
      removeErrorMessage(draftMsg.uuid);
    } catch (exception) {
      log.info('[CS-Service] not notify to user if there is any error');
      Sentry.captureException(exception);
    }
    sendMessageFail(draftMsg.uuid);
    _isProcessingDraftMessages = false;
    log.info('[CS-Service][end] processMessages hasDraft');
    processMessages();
  }

  @override
  Future<List<DraftCustomerSupport>> getDrafts(String issueID) async {
    return _draftCustomerSupportDao.getDrafts(issueID);
  }

  Future<PostedMessageResponse> createIssue(
    String reportIssueType,
    String? message,
    List<SendAttachment>? attachments, {
    String? title,
    List<String>? mutedText,
    String? announcementID,
  }) async {
    var issueTitle = title ?? message;
    if (issueTitle == null || issueTitle.isEmpty) {
      issueTitle = attachments?.first.title ?? 'Unnamed';
    }

    // add tags
    var tags = [reportIssueType];
    if (Platform.isIOS) {
      tags.add("iOS");
    } else if (Platform.isAndroid) {
      tags.add("android");
    }

    // Muted Message
    var mutedMessage = "";
    final deviceID = await getDeviceID();
    if (deviceID != null) {
      mutedMessage += "**DeviceID**: $deviceID\n";
    }

    final version = (await PackageInfo.fromPlatform()).version;
    mutedMessage += "**Version**: $version\n";

    final deviceInfo = await DeviceInfo.instance.getUserDeviceInfo();
    mutedMessage += "**DeviceName**: ${deviceInfo.machineName}\n";
    mutedMessage += "**OSVersion**: ${deviceInfo.oSVersion}\n";

    for (var mutedMsg in (mutedText ?? [])) {
      mutedMessage += "$mutedMsg\n";
    }

    final submitMessage = "[MUTED]\n$mutedMessage[/MUTED]\n\n${message ?? ''}";

    final payload = {
      'attachments': attachments ?? [],
      'title': issueTitle,
      'message': submitMessage,
      'tags': tags,
      'announcement_context_id': announcementID ?? "",
    };

    return await _customerSupportApi.createIssue(payload);
  }

  Future<PostedMessageResponse> commentIssue(String issueID, String? message,
      List<SendAttachment>? attachments) async {
    final payload = {
      'attachments': attachments ?? [],
      'message': message ?? '',
    };

    return await _customerSupportApi.commentIssue(issueID, payload);
  }

  @override
  Future<String> getStoredDirectory() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    return '$appDocumentsPath/customer-support';
  }

  @override
  Future<String> storeFile(String filename, List<int> bytes) async {
    log.info('[start] storeFile $filename');
    final directory = await getStoredDirectory();
    String filePath = '$directory/$filename'; // 3

    File file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    log.info('[done] storeFile $filename');
    return file.path;
  }

  @override
  Future reopen(String issueID) async {
    return _customerSupportApi.reOpenIssue(issueID);
  }

  @override
  Future rateIssue(String issueID, int rating) async {
    return _customerSupportApi.rateIssue(issueID, rating);
  }

  @override
  Future<List<ChatThread>> getIssuesAndAnnouncement() async {
    List<ChatThread> result = [];
    List<Issue> issues = await getIssues();
    List<AnnouncementLocal> announcements =
        await _announcementDao.getAnnouncements();
    if (issues.isNotEmpty && announcements.isNotEmpty) {
      announcements.removeWhere((element) => issues.any((i) {
            if (i.announcementID == element.announcementContextId) {
              i.announcement = element;
              return true;
            }
            return false;
          }));
    }
    result.addAll(issues);
    result.addAll(announcements);
    numberOfIssuesInfo.value = [
      result.length,
      result
          .where((element) => (element is Issue)
              ? element.unread > 0
              : (element is AnnouncementLocal)
                  ? element.unread
                  : false)
          .length,
    ];
    result.sort((a, b) {
      final aTimestamp = _getTimestamp(a);
      final bTimestamp = _getTimestamp(b);
      return bTimestamp.compareTo(aTimestamp);
    });
    return result;
  }

  int _getTimestamp(Object a) {
    if (a is Issue) {
      final timestamp =
          a.draft?.createdAt ?? a.lastMessage?.timestamp ?? a.timestamp;
      return timestamp.millisecondsSinceEpoch;
    } else if (a is AnnouncementLocal) {
      return a.createdAt;
    } else {
      return 0;
    }
  }

  @override
  Future<void> fetchAnnouncement() async {
    final lastPullTime = _configurationService.getAnnouncementLastPullTime();
    final announcements = await _announcementApi.getAnnouncements(
        lastPullTime: lastPullTime ?? 0);
    final pullTime = DateTime.now().millisecondsSinceEpoch;
    await _configurationService.setAnnouncementLastPullTime(pullTime);
    final metricClient = injector.get<MetricClientService>();
    for (var announcement in announcements) {
      if (await _announcementDao
              .getAnnouncement(announcement.announcementContextId) ==
          null) {
        metricClient.addEvent(
          MixpanelEvent.receiveAnnouncement,
          data: {
            "id": announcement.announcementContextId,
            "type": announcement.type,
            "title": announcement.title,
          },
        );
      }
      await _announcementDao
          .insertAnnouncement(AnnouncementLocal.fromAnnouncement(announcement));
    }
  }

  @override
  Future<void> markAnnouncementAsRead(String announcementID) async {
    await _announcementDao.updateRead(announcementID, false);
  }

  @override
  Future<void> createAnnouncement(AnnouncementID type) async {
    final body = {"announcement_context_id": type.value};
    await _announcementApi.callAnnouncement(body);
    await fetchAnnouncement();
    final announcement = await _announcementDao.getAnnouncement(type.value);
    if (announcement != null) {
      await getIssuesAndAnnouncement();
      showInfoNotification(
          const Key("Announcement"), "au_has_announcement".tr(),
          addOnTextSpan: [
            TextSpan(
                text: "tap_to_view".tr(),
                style: Theme.of(injector<NavigationService>()
                        .navigatorKey
                        .currentContext!)
                    .textTheme
                    .ppMori400Green14),
          ], openHandler: () {
        injector<NavigationService>().navigateTo(
          AppRouter.supportThreadPage,
          arguments: NewIssuePayload(
            reportIssueType: ReportIssueType.Announcement,
            announcement: announcement,
          ),
        );
      });
    }
  }

  @override
  Future<AnnouncementLocal?> findAnnouncementFromIssueId(String issueId) async {
    await fetchAnnouncement();
    final issues = await _customerSupportApi.getIssues();
    final issue =
        issues.firstWhereOrNull((element) => element.issueID == issueId);
    if (issue != null && issue.announcementID != null) {
      return await _announcementDao.getAnnouncement(issue.announcementID!);
    } else {
      return null;
    }
  }

  @override
  Future<AnnouncementLocal?> findAnnouncement(String announcementID) async {
    return await _announcementDao.getAnnouncement(announcementID);
  }
}
