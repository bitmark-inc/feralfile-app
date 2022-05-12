import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:autonomy_flutter/database/dao/draft_customer_support_dao.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  Future<IssueDetails> getDetails(String issueID);
  Future<List<Issue>> getIssues();
  Future draftMessage(DraftCustomerSupport draft);
  Future processMessages();
  Future<List<DraftCustomerSupport>> getDrafts(String issueID);
  Future<String> getStoredDirectory();
  Future<String> storeFile(String filename, List<int> bytes);
  Future reopen(String issueID);
}

class CustomerSupportServiceImpl extends CustomerSupportService {
  final DraftCustomerSupportDao _draftCustomerSupportDao;
  final CustomerSupportApi _customerSupportApi;
  ValueNotifier<List<int>?> numberOfIssuesInfo = ValueNotifier(null);
  ValueNotifier<int> triggerReloadMessages = ValueNotifier(0);
  ValueNotifier<CustomerSupportUpdate?> customerSupportUpdate =
      ValueNotifier(null);
  Map<String, String> tempIssueIDMap = {};

  CustomerSupportServiceImpl(
    this._draftCustomerSupportDao,
    this._customerSupportApi,
  );

  bool _isProcessingDraftMessages = false;

  Future<List<Issue>> getIssues() async {
    final issues = await _customerSupportApi.getIssues();
    final drafts = await _draftCustomerSupportDao.getAllDrafts();

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

    numberOfIssuesInfo.value = [
      issues.length,
      issues.where((element) => element.unread > 0).length,
    ];

    return issues;
  }

  Future<IssueDetails> getDetails(String issueID) async {
    return await _customerSupportApi.getDetails(issueID);
  }

  Future draftMessage(DraftCustomerSupport draft) async {
    await _draftCustomerSupportDao.insertDraft(draft);
    processMessages();
  }

  Future processMessages() async {
    log.info('[CS-Service][trigger] processMessages');
    if (_isProcessingDraftMessages) return;

    log.info('[CS-Service][start] processMessages');
    final draftMsgs = await _draftCustomerSupportDao.fetchDrafts(1);

    if (draftMsgs.isEmpty) return;
    log.info('[CS-Service][start] processMessages hasDraft');
    _isProcessingDraftMessages = true;
    final draftMsg = draftMsgs.first;

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
    } catch (exception) {
      log.info('[CS-Service] not notify to user if there is any error');
      Sentry.captureException(exception);
    }

    _isProcessingDraftMessages = false;
    log.info('[CS-Service][end] processMessages hasDraft');
    processMessages();
  }

  Future<List<DraftCustomerSupport>> getDrafts(String issueID) async {
    return _draftCustomerSupportDao.getDrafts(issueID);
  }

  Future<PostedMessageResponse> createIssue(
    String reportIssueType,
    String? message,
    List<SendAttachment>? attachments, {
    String? title,
    List<String>? mutedText,
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

    for (var mutedMsg in (mutedText ?? [])) {
      mutedMessage += "$mutedMsg\n";
    }
    final submitMessage = "[MUTED]\n$mutedMessage[/MUTED]\n\n$message";

    final payload = {
      'attachments': attachments ?? [],
      'title': issueTitle,
      'message': submitMessage,
      'tags': tags,
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

  Future<String> getStoredDirectory() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    return '$appDocumentsPath/customer-support';
  }

  Future<String> storeFile(String filename, List<int> bytes) async {
    log.info('[start] storeFile $filename');
    final directory = await getStoredDirectory();
    String filePath = '$directory/$filename'; // 3

    File file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    log.info('[done] storeFile $filename');
    return file.path;
  }

  Future reopen(String issueID) async {
    return _customerSupportApi.reOpenIssue(issueID);
  }
}
