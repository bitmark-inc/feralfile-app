//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart' as app;
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart' as logUtil;
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';

abstract class SupportThreadPayload {}

class NewIssuePayload extends SupportThreadPayload {
  final String reportIssueType;

  NewIssuePayload({
    required this.reportIssueType,
  });
}

class DetailIssuePayload extends SupportThreadPayload {
  final String reportIssueType;
  final String issueID;

  DetailIssuePayload({
    required this.reportIssueType,
    required this.issueID,
  });
}

class ExceptionErrorPayload extends SupportThreadPayload {
  final String sentryID;
  final String metadata;

  ExceptionErrorPayload({
    required this.sentryID,
    required this.metadata,
  });
}

class SupportThreadPage extends StatefulWidget {
  final SupportThreadPayload payload;

  const SupportThreadPage({
    Key? key,
    required this.payload,
  }) : super(key: key);

  @override
  _SupportThreadPageState createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends State<SupportThreadPage> {
  String _reportIssueType = '';
  String? _issueID;

  List<types.Message> _messages = [];
  List<types.Message> _draftMessages = [];
  final _user = const types.User(id: 'user');
  final _bitmark = const types.User(id: 'bitmark');

  String _status = '';

  late var _forceAccountsViewRedraw;
  var _sendIcon = "assets/images/sendMessage.svg";
  final _introMessagerID = const Uuid().v4();
  final _resolvedMessagerID = const Uuid().v4();
  types.TextMessage get _introMessager => types.TextMessage(
        author: _bitmark,
        id: _introMessagerID,
        text: ReportIssueType.introMessage(_reportIssueType),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  types.CustomMessage get _resolvedMessager => types.CustomMessage(
        id: _resolvedMessagerID,
        author: _bitmark,
        metadata: {"status": "resolved"},
      );

  @override
  void initState() {
    injector<CustomerSupportService>().processMessages();
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .addListener(_loadIssueDetails);

    injector<CustomerSupportService>()
        .customerSupportUpdate
        .addListener(_loadCustomerSupportUpdates);

    final payload = widget.payload;
    if (payload is NewIssuePayload) {
      _reportIssueType = payload.reportIssueType;
      if (_reportIssueType == ReportIssueType.Bug) {
        Future.delayed(Duration(milliseconds: 300), () {
          _askForAttachCrashLog(context, onConfirm: (attachCrashLog) {
            if (attachCrashLog) {
              _addAppLogs();
            } else {
              UIHelper.hideInfoDialog(context);
            }
          });
        });
      }
    } else if (payload is DetailIssuePayload) {
      _reportIssueType = payload.reportIssueType;
      _issueID =
          injector<CustomerSupportService>().tempIssueIDMap[payload.issueID] ??
              payload.issueID;
    } else if (payload is ExceptionErrorPayload) {
      _reportIssueType = ReportIssueType.Exception;
    }

    memoryValues.viewingSupportThreadIssueID = _issueID;
    _forceAccountsViewRedraw = Object();
    super.initState();

    _loadDrafts();

    if (_issueID != null && !_issueID!.startsWith("TEMP")) {
      _loadIssueDetails();
    }
  }

  @override
  void dispose() {
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .removeListener(_loadIssueDetails);
    injector<CustomerSupportService>()
        .customerSupportUpdate
        .removeListener(_loadCustomerSupportUpdates);

    memoryValues.viewingSupportThreadIssueID = null;
    super.dispose();
  }

  void _askForAttachCrashLog(BuildContext context,
      {required void Function(bool attachCrashLog) onConfirm}) {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);
    UIHelper.showDialog(
      context,
      "Attach crash log?",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "Would you like to attach a crash log with your support request? The crash log is anonymous and will help our engineers identify the issue.",
              style: theme.textTheme.bodyText1),
          SizedBox(height: 40),
          AuFilledButton(
            text: "ATTACH CRASH LOG",
            color: theme.primaryColor,
            textStyle: TextStyle(
                color: theme.backgroundColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            onPress: () => onConfirm(true),
          ),
          AuFilledButton(
            text: "CONTINUE WITHOUT CRASH LOG",
            textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            onPress: () => onConfirm(false),
          ),
          SizedBox(height: 40),
        ],
      ),
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<types.Message> messages = (_draftMessages + _messages);
    if (_status == 'closed' || _status == 'clickToReopen') {
      messages.insert(0, _resolvedMessager);
    }

    if (_issueID == null || messages.length > 0) {
      messages.add(_introMessager);
    }

    return Scaffold(
        appBar: getBackAppBar(
          context,
          title: ReportIssueType.toTitle(_reportIssueType).toUpperCase(),
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
            margin: EdgeInsets.zero,
            child: Chat(
              l10n: const ChatL10nEn(
                inputPlaceholder: 'Write a message',
              ),
              bubbleBuilder: _bubbleBuilder,
              theme: _chatTheme,
              sendButtonVisibilityMode: SendButtonVisibilityMode.always,
              customMessageBuilder: _customMessageBuilder,
              emptyState: CupertinoActivityIndicator(),
              messages: messages,
              onAttachmentPressed: _handleAtachmentPressed,
              onSendPressed: _handleSendPressed,
              onTextChanged: (text) {
                setState(() {
                  _sendIcon = text.trim() != ''
                      ? "assets/images/sendMessageFilled.svg"
                      : "assets/images/sendMessage.svg";
                });
              },
              user: _user,
              customBottomWidget:
                  _status == 'closed' ? SizedBox(height: 40) : null,
            )));
  }

  Widget _bubbleBuilder(
    Widget child, {
    required message,
    required nextMessageInGroup,
  }) {
    var color = _user.id != message.author.id
        ? AppColorTheme.chatSecondaryColor
        : AppColorTheme.chatPrimaryColor;

    if (message.type == types.MessageType.image) {
      color = Colors.transparent;
    }

    return Bubble(
      child: child,
      color: color,
      margin: nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 6)
          : null,
      nip: nextMessageInGroup
          ? BubbleNip.no
          : _user.id != message.author.id
              ? BubbleNip.leftBottom
              : BubbleNip.rightBottom,
    );
  }

  Widget _customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    switch (message.metadata?["status"]) {
      case "resolved":
        return Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          color: AppColorTheme.chatSecondaryColor,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    "Issue resolved.\nOur team thanks you for helping us improve Autonomy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "AtlasGrotesk-Bold",
                        fontWeight: FontWeight.w700,
                        height: 1.377)),
                SizedBox(height: 24),
                TextButton(
                    onPressed: () {
                      setState(() {
                        _status = "clickToReopen";
                      });
                    },
                    style: textButtonNoPadding,
                    child: Text("Still experiencing the same problem?",
                        style: whitelinkStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ))),
              ]),
        );

      default:
        return SizedBox();
    }
  }

  void _loadIssueDetails() async {
    if (_issueID == null) return;
    final issueDetails =
        await injector<CustomerSupportService>().getDetails(_issueID!);

    final _parsedMessages = (await Future.wait(
            issueDetails.messages.map((e) => _convertChatMessage(e, null))))
        .expand((i) => i)
        .toList();

    if (mounted)
      setState(() {
        _status = issueDetails.issue.status;
        _reportIssueType = issueDetails.issue.reportIssueType;
        _messages = _parsedMessages;
      });
  }

  Future _loadDrafts() async {
    if (_issueID == null) return;
    final drafts =
        await injector<CustomerSupportService>().getDrafts(_issueID!);
    final draftMessages =
        (await Future.wait(drafts.map((e) => _convertChatMessage(e, null))))
            .expand((i) => i)
            .toList();

    if (mounted)
      setState(() {
        _draftMessages = draftMessages;
      });
  }

  void _loadCustomerSupportUpdates() async {
    final update =
        injector<CustomerSupportService>().customerSupportUpdate.value;
    if (update == null) return;
    if (update.draft.issueID != _issueID) return;

    _issueID = update.response.issueID;
    memoryValues.viewingSupportThreadIssueID = _issueID;
    final newMessages =
        await _convertChatMessage(update.response.message, update.draft.uuid);

    setState(() {
      _draftMessages
          .removeWhere((element) => element.id.startsWith(update.draft.uuid));
      _messages.insertAll(0, newMessages);
    });
  }

  Future _submit(String messageType, DraftCustomerSupportData data) async {
    logUtil.log.info('[CS-Thread][start] _submit $messageType - $data');
    List<String> mutedMessages = [];
    if (_issueID == null) {
      messageType = CSMessageType.CreateIssue.rawValue;
      _issueID = "TEMP-" + Uuid().v4();

      final payload = widget.payload;
      if (payload is ExceptionErrorPayload) {
        final _sentryID = payload.sentryID;
        if (_sentryID.isNotEmpty) {
          mutedMessages.add(
              "[SENTRY REPORT $_sentryID](https://sentry.io/organizations/bitmark-inc/issues/?query=$_sentryID)");
        }

        if (payload.metadata.isNotEmpty) {
          mutedMessages.add("METADATA EXCEPTION: ${payload.metadata}");
        }
      }
    }

    final draft = DraftCustomerSupport(
      uuid: Uuid().v4(),
      issueID: _issueID!,
      type: messageType,
      data: json.encode(data),
      createdAt: DateTime.now(),
      reportIssueType: _reportIssueType,
      mutedMessages: mutedMessages.join("[SEPARATOR]"),
    );

    _draftMessages.insertAll(0, await _convertChatMessage(draft, null));

    if (_issueID != null && _status == 'clickToReopen') {
      setState(() {
        _status = "reopening";
      });
      await injector<CustomerSupportService>().reopen(_issueID!);
      _status = "open";
    }

    await injector<CustomerSupportService>().draftMessage(draft);
    setState(() {
      _sendIcon = "assets/images/sendMessage.svg";
      _forceAccountsViewRedraw = Object();
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    _submit(
      CSMessageType.PostMessage.rawValue,
      DraftCustomerSupportData(text: message.text, attachments: null),
    );
  }

  Future _addAppLogs() async {
    final file = await logUtil.getLogFile();
    final bytes = await file.readAsBytes();
    final auditBytes = await injector<AuditService>().export();
    final combinedBytes = bytes + auditBytes;
    final filename =
        "${combinedBytes.length}_${DateTime.now().microsecondsSinceEpoch}.logs";

    final localPath = await injector<CustomerSupportService>()
        .storeFile(filename, combinedBytes);

    await _submit(
        CSMessageType.PostLogs.rawValue,
        DraftCustomerSupportData(
          text: null,
          attachments: [LocalAttachment(fileName: filename, path: localPath)],
        ));

    Navigator.pop(context);
  }

  void _handleAtachmentPressed() {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);

    UIHelper.showDialog(
      context,
      "Attach file",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            style: textButtonNoPadding,
            onPressed: () {
              _handleImageSelection();
              Navigator.of(context).pop();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Photo', style: theme.textTheme.headline4),
            ),
          ),
          addDialogDivider(),
          TextButton(
            style: textButtonNoPadding,
            onPressed: () async {
              await _addAppLogs();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Debug log', style: theme.textTheme.headline4),
            ),
          ),
          SizedBox(height: 40),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("CANCEL",
                  style: theme.textTheme.button?.copyWith(color: Colors.white)),
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
      isDismissible: true,
    );
  }

  void _handleImageSelection() async {
    logUtil.log.info('[_handleImageSelection] begin');
    final result = await ImagePicker().pickMultiImage();
    if (result == null) return;

    final attachments = await Future.wait(result.map((element) async {
      final bytes = await element.readAsBytes();
      final fileName = "${bytes.length}_${element.name}";
      final localPath =
          await injector<CustomerSupportService>().storeFile(fileName, bytes);
      return LocalAttachment(path: localPath, fileName: fileName);
    }));

    await _submit(
        CSMessageType.PostPhotos.rawValue,
        DraftCustomerSupportData(
          text: null,
          attachments: attachments,
        ));
  }

  Future<List<types.Message>> _convertChatMessage(
      dynamic message, String? tempID) async {
    late var id, author, status, createdAt, text;

    if (message is app.Message) {
      id = tempID ?? "${message.id}";
      author = message.from.contains("did:key") ? _user : _bitmark;
      status = types.Status.delivered;
      createdAt = message.timestamp;
      text = message.filteredMessage;
      //
    } else if (message is DraftCustomerSupport) {
      id = message.uuid;
      author = _user;
      status = types.Status.sending;
      createdAt = message.createdAt;
      text = message.draftData.text;
      //
    } else {
      return [];
    }

    List<types.Message> result = [];

    if (text is String && text.isNotEmpty && text != EMPTY_ISSUE_MESSAGE) {
      result.add(types.TextMessage(
        id: id,
        author: author,
        createdAt: createdAt.millisecondsSinceEpoch,
        text: text,
        status: status,
        showStatus: true,
      ));
    }

    final storedDirectory =
        await injector<CustomerSupportService>().getStoredDirectory();
    List<String> titles = [];
    List<String> uris = [];
    List<String> contentTypes = [];

    if (message is app.Message) {
      for (var attachment in message.attachments) {
        titles.add(attachment.title);
        uris.add(storedDirectory + "/" + attachment.title);
        contentTypes.add(attachment.contentType);
      }
      //
    } else if (message is DraftCustomerSupport) {
      for (var attachment in message.draftData.attachments ?? []) {
        titles.add(attachment.fileName);
        uris.add(attachment.path);
        contentTypes.add(message.type == CSMessageType.PostPhotos.rawValue
            ? 'image'
            : 'logs');
      }
    }

    for (var i = 0; i < titles.length; i += 1) {
      if (contentTypes[i].contains("image")) {
        result.add(types.ImageMessage(
          id: id + '$i',
          author: author,
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
          showStatus: true,
          name: titles[i],
          size: 0,
          uri: uris[i],
        ));
      } else {
        final sizeAndRealTitle =
            ReceiveAttachment.extractSizeAndRealTitle(titles[i]);
        result.add(types.FileMessage(
          id: id + '$i',
          author: author,
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
          showStatus: true,
          name: sizeAndRealTitle[1],
          size: sizeAndRealTitle[0] ?? 0,
          uri: uris[i],
        ));
      }
    }

    return result;
  }

  DefaultChatTheme get _chatTheme {
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      inputPadding: EdgeInsets.fromLTRB(0, 24, 0, 20),
      inputMargin: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      inputBackgroundColor: Colors.black,
      inputTextStyle: appTextTheme.bodyText1!,
      inputTextColor: Colors.white,
      attachmentButtonIcon: SvgPicture.asset(
        "assets/images/joinFile.svg",
        color: Colors.white,
      ),
      inputBorderRadius: BorderRadius.zero,
      sendButtonIcon: SvgPicture.asset(
        _sendIcon,
      ),
      inputTextCursorColor: Colors.white,
      emptyChatPlaceholderTextStyle: appTextTheme.headline4!
          .copyWith(color: AppColorTheme.secondarySpanishGrey),
      dateDividerMargin: EdgeInsets.symmetric(vertical: 12),
      dateDividerTextStyle: TextStyle(
          color: AppColorTheme.chatDateDividerColor,
          fontSize: 12,
          fontFamily: "AtlasGrotesk",
          height: 1.377),
      primaryColor: Colors.transparent,
      sentMessageBodyTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: "AtlasGrotesk",
          height: 1.377),
      secondaryColor: AppColorTheme.chatSecondaryColor,
      receivedMessageBodyTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: "AtlasGrotesk",
          height: 1.377),
      receivedMessageDocumentIconColor: Colors.white,
      sentMessageDocumentIconColor: Colors.white,
      documentIcon: Image.asset(
        "assets/images/chatFileIcon.png",
        width: 20,
      ),
      sentMessageCaptionTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          fontFamily: "AtlasGrotesk-Light",
          height: 1.377),
      receivedMessageCaptionTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          fontFamily: "AtlasGrotesk-Light",
          height: 1.377),
      sendingIcon: Container(
        width: 16,
        height: 12,
        padding: EdgeInsets.only(left: 3),
        child: CircularProgressIndicator(
          color: AppColorTheme.secondarySpanishGrey,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
