//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/database/dao/draft_customer_support_dao.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/gateway/rendering_report_api.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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

  List<String>? get errorMessages;

  Future<IssueDetails> getDetails(String issueID);

  Future<List<Issue>> getIssues();

  Future draftMessage(DraftCustomerSupport draft);

  Future processMessages();

  Future<List<DraftCustomerSupport>> getDrafts(String issueID);

  Future<String> getStoredDirectory();

  Future<String> storeFile(String filename, List<int> bytes);

  Future reopen(String issueID);

  Future rateIssue(String issueID, int rating);

  Future<String> createRenderingIssueReport(
    AssetToken token,
    List<String> topics,
  );

  Future reportIPFSLoadingError(AssetToken token);

  Future<void> removeErrorMessage(String uuid, {bool isDelete = false});

  void sendMessageFail(String uuid);
}

class CustomerSupportServiceImpl extends CustomerSupportService {
  static const int _ipfsReportThreshold = 24 * 60 * 60 * 1000; // 1 day.

  final DraftCustomerSupportDao _draftCustomerSupportDao;
  final CustomerSupportApi _customerSupportApi;
  final RenderingReportApi _renderingReportApi;
  final AccountService _accountService;
  final ConfigurationService _configurationService;
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
    this._renderingReportApi,
    this._accountService,
    this._configurationService,
  );

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

    final submitMessage = "[MUTED]\n$mutedMessage[/MUTED]\n\n${message ?? ''}";

    final payload = {
      'attachments': attachments ?? [],
      'title': issueTitle,
      'message': submitMessage,
      'tags': tags,
    };

    return await _customerSupportApi.createIssue(payload);
  }

  @override
  Future<String> createRenderingIssueReport(
    AssetToken token,
    List<String> topics,
  ) async {
    /** Generate metadata
     * Format:
     * [Platform - Version - HashedAccountDID]
     * [TokenIndexerID - Topices]
     */
    var metadata = "";

    final defaultAccount = await _accountService.getDefaultAccount();
    final accountDID = await defaultAccount.getAccountDID();
    final accountHMACSecret =
        await _configurationService.getAccountHMACSecret();

    final hashedAccountID = Hmac(sha256, utf8.encode(accountHMACSecret))
        .convert(utf8.encode(accountDID));

    String platform = "";
    if (Platform.isIOS) {
      platform = "iOS";
    } else if (Platform.isAndroid) {
      platform = "android";
    }

    final version = (await PackageInfo.fromPlatform()).version;

    metadata =
        "\n[$platform - $version - $hashedAccountID]\n[${token.id} - ${topics.join(", ")}]";

    // Extract Collection Value
    // Etherem blockchain: => pass contract as value: k_$contractAddress
    // Tezos / FeralFile blockchain => pass arworkID as value: a_$artworkID
    var collection = token.contractAddress;
    if (collection != null && collection.isNotEmpty) {
      collection = "k_$collection";
    }

    if (collection == null ||
        collection.isEmpty ||
        ['tezos', 'bitmark'].contains(token.blockchain)) {
      collection = "a_${token.assetID}";
    }

    // Request API
    final payload = {
      "artwork": token.assetID,
      "creator": token.artistName ?? 'unknown',
      "collection": collection,
      "token_url": token.assetURL,
      "metadata": metadata,
    };

    final result = await _renderingReportApi.report(payload);
    final githubURL = result["url"];
    if (githubURL == null) {
      throw SystemException("_renderingReportApi missing url $result");
    }
    return githubURL;
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
  Future reportIPFSLoadingError(AssetToken token) async {
    final reportBox = await Hive.openBox("au_ipfs_reports");
    final int lastReportTime = reportBox.get(token.id) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > lastReportTime + _ipfsReportThreshold) {
      reportBox.put(token.id, now);
      await createRenderingIssueReport(token, ["IPFS Loading"]);
    }
  }
}
