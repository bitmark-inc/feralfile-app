import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';

import 'package:flutter/material.dart';

import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class CustomerSupportService {
  ValueNotifier<List<int>?>
      get numberOfIssuesInfo; // [numberOfIssues, numberOfUnreadIssues]
  ValueNotifier<int> get triggerReloadMessages;

  Future<IssueDetails> getDetails(String issueID);
  Future<List<Issue>> getIssues();
  Future<PostedMessageResponse> createIssue(
      String reportIssueType, String message, List<SendAttachment> attachments);
  Future<PostedMessageResponse> commentIssue(
      String issueID, String message, List<SendAttachment> attachments);
  Future<String> getStoredDirectory();
  Future storeFile(String filename, List<int> bytes);
  Future reopen(String issueID);
}

class CustomerSupportServiceImpl extends CustomerSupportService {
  final CustomerSupportApi _customerSupportApi;
  ValueNotifier<List<int>?> numberOfIssuesInfo = ValueNotifier(null);
  ValueNotifier<int> triggerReloadMessages = ValueNotifier(0);

  CustomerSupportServiceImpl(this._customerSupportApi);

  Future<List<Issue>> getIssues() async {
    final issues = await _customerSupportApi.getIssues();
    numberOfIssuesInfo.value = [
      issues.length,
      issues.where((element) => element.unread > 0).length,
    ];

    return issues;
  }

  Future<IssueDetails> getDetails(String issueID) async {
    return await _customerSupportApi.getDetails(issueID);
  }

  Future<PostedMessageResponse> createIssue(String reportIssueType,
      String message, List<SendAttachment> attachments) async {
    var title = message;
    if (title.isEmpty) {
      title = attachments.first.title;
    }

    // add tags
    var tags = [reportIssueType];

    final deviceID = await getDeviceID();
    if (deviceID != null) {
      tags.add(deviceID);
    }

    if (Platform.isIOS) {
      tags.add("iOS");
    } else if (Platform.isAndroid) {
      tags.add("android");
    }
    tags.add((await PackageInfo.fromPlatform()).version);
    tags.add(await isAppCenterBuild() ? 'dev' : 'prod');

    if (title.length > 170) {
      title = title.substring(0, 170);
    }

    final payload = {
      'attachments': attachments,
      'title': title,
      'message': attachments.length > 0 ? '' : message,
      'tags': tags,
    };

    return await _customerSupportApi.createIssue(payload);
  }

  Future<PostedMessageResponse> commentIssue(
      String issueID, String message, List<SendAttachment> attachments) async {
    final payload = {
      'attachments': attachments,
      'message': attachments.length > 0 ? '' : message,
    };

    return await _customerSupportApi.commentIssue(issueID, payload);
  }

  Future<String> getStoredDirectory() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    return '$appDocumentsPath/customer-support';
  }

  Future storeFile(String filename, List<int> bytes) async {
    log.info('[start] storeFile $filename');
    final directory = await getStoredDirectory();
    String filePath = '$directory/$filename'; // 3

    File file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    log.info('[done] storeFile $filename');
  }

  Future reopen(String issueID) async {
    return _customerSupportApi.reOpenIssue(issueID);
  }
}
