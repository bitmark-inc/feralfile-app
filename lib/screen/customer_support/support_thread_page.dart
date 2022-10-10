//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart' as app;
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart' as log_util;
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:bubble/bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../util/datetime_ext.dart';

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
  final String status;
  final bool isRated;

  DetailIssuePayload(
      {required this.reportIssueType,
      required this.issueID,
      this.status = "",
      this.isRated = false});
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
  State<SupportThreadPage> createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends State<SupportThreadPage> {
  String _reportIssueType = '';
  String? _issueID;

  List<types.Message> _messages = [];
  List<types.Message> _draftMessages = [];
  final _user = const types.User(id: 'user');
  final _bitmark = const types.User(id: 'bitmark');

  String _status = '';
  bool _isRated = false;

  late var _forceAccountsViewRedraw;
  var _sendIcon = "assets/images/sendMessage.svg";
  final _introMessengerID = const Uuid().v4();
  final _resolvedMessengerID = const Uuid().v4();
  final _askRatingMessengerID = const Uuid().v4();
  final _askReviewMessengerID = const Uuid().v4();

  types.TextMessage get _introMessenger => types.TextMessage(
        author: _bitmark,
        id: _introMessengerID,
        text: ReportIssueType.introMessage(_reportIssueType),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  types.CustomMessage get _resolvedMessenger => types.CustomMessage(
        id: _resolvedMessengerID,
        author: _bitmark,
        metadata: const {"status": "resolved"},
      );

  types.TextMessage get _askRatingMessenger => types.TextMessage(
        author: _bitmark,
        id: _askRatingMessengerID,
        text: "rate_issue".tr(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  types.TextMessage get _askReviewMessenger => types.TextMessage(
        author: _bitmark,
        id: _askReviewMessengerID,
        text: "care_to_share".tr(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
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
        Future.delayed(const Duration(milliseconds: 300), () {
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
      _status = payload.status;
      _isRated = payload.isRated;
      _issueID =
          injector<CustomerSupportService>().tempIssueIDMap[payload.issueID] ??
              payload.issueID;
    } else if (payload is ExceptionErrorPayload) {
      _reportIssueType = ReportIssueType.Exception;
      Future.delayed(const Duration(milliseconds: 300), () {
        _askForAttachCrashLog(context, onConfirm: (attachCrashLog) {
          if (attachCrashLog) {
            _addAppLogs();
          } else {
            UIHelper.hideInfoDialog(context);
          }
        });
      });
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
    final theme = Theme.of(context);
    UIHelper.showDialog(
      context,
      "attach_crash_log".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ask_attach_crash".tr(),
              //"Would you like to attach a crash log with your support request? The crash log is anonymous and will help our engineers identify the issue.",
              style: theme.primaryTextTheme.bodyText1),
          const SizedBox(height: 40),
          AuFilledButton(
            text: "attach_crash_logH".tr(),
            color: theme.colorScheme.secondary,
            textStyle: theme.textTheme.button,
            onPress: () => onConfirm(true),
          ),
          AuFilledButton(
            text: "conti_no_crash_log".tr(),
            textStyle: theme.primaryTextTheme.button,
            onPress: () => onConfirm(false),
          ),
          const SizedBox(height: 40),
        ],
      ),
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<types.Message> messages = (_draftMessages + _messages);

    ////// this convert rating messages to customMessage type, then convert the string messages to rating bars
    for (int i = 0; i < messages.length; i++) {
      if (_isRating(messages[i])) {
        final ratingMessengerID = const Uuid().v4();
        final ratingMessenger = types.CustomMessage(
          id: ratingMessengerID,
          author: _user,
          metadata: {
            "status": "rating",
            "rating": messages[i].metadata!["rating"],
          },
        );
        messages[i] = ratingMessenger;
      }
    }

    if (_status == 'closed' || _status == 'clickToReopen') {
      final ratingIndex = _firstRatingIndex(messages);
      messages.insert(ratingIndex + 1, _resolvedMessenger);
      messages.insert(ratingIndex + 1, _askRatingMessenger);
      if (ratingIndex > -1 && _status == 'closed') {
        messages.insert(ratingIndex, _askReviewMessenger);
      }
    }

    for (int i = 0; i < messages.length; i++) {
      if (_isRatingMessage(messages[i])) {
        if (messages[i + 1] != _askRatingMessenger) {
          messages.insert(i + 1, _resolvedMessenger);
          messages.insert(i + 1, _askRatingMessenger);
        }
        if (i > 0 && _isCustomerSupportMessage(messages[i - 1])) {
          messages.insert(i, _askReviewMessenger);
          i++;
        }
      }
    }

    if (_issueID == null || messages.isNotEmpty) {
      messages.add(_introMessenger);
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
              l10n: ChatL10nEn(
                inputPlaceholder: "write_message".tr(),
              ),
              customDateHeaderText: getChatDateTimeRepresentation,
              bubbleBuilder: _bubbleBuilder,
              theme: _chatTheme,
              customMessageBuilder: _customMessageBuilder,
              emptyState: const CupertinoActivityIndicator(),
              messages: messages,
              onAttachmentPressed: _handleAtachmentPressed,
              onSendPressed: _handleSendPressed,
              inputOptions: InputOptions(
                  sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  onTextChanged: (text) {
                    if (_sendIcon == "assets/images/sendMessageFilled.svg" &&
                            text.trim() == '' ||
                        _sendIcon == "assets/images/sendMessage.svg" &&
                            text.trim() != '') {
                      setState(() {
                        _sendIcon = text.trim() != ''
                            ? "assets/images/sendMessageFilled.svg"
                            : "assets/images/sendMessage.svg";
                      });
                    }
                  }),
              user: _user,
              customBottomWidget: _isRated == false && _status == 'closed'
                  ? MyRatingBar(
                      submit:
                          (String messageType, DraftCustomerSupportData data,
                                  {bool isRating = false}) =>
                              _submit(messageType, data, isRating: isRating))
                  : null,
            )));
  }

  bool _isRatingMessage(types.Message message) {
    if (message is types.CustomMessage) {
      if (message.metadata?["rating"] == null) return false;
      if (message.metadata?["rating"] > 0) {
        return true;
      }
    }
    return false;
  }

  bool _isCustomerSupportMessage(types.Message message) {
    if (message is types.TextMessage) {
      return message.text.contains(RATING_MESSAGE_START);
    }
    return false;
  }

  int _firstRatingIndex(List<types.Message> messages) {
    for (int i = 0; i < messages.length; i++) {
      if (_isRatingMessage(messages[i])) return i;
      if (_isCustomerSupportMessage(messages[i]) == false) return -1;
    }
    return -1;
  }

  Widget _ratingBar(int rating) {
    if (rating == 0) return const SizedBox();
    return RatingBar.builder(
      initialRating: rating.toDouble(),
      minRating: 1,
      itemSize: 24,
      itemPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: AppColor.primaryBlack,
      ),
      unratedColor: AppColor.secondarySpanishGrey,
      ignoreGestures: true,
      onRatingUpdate: (double value) {},
    );
  }

  Widget _bubbleBuilder(
    Widget child, {
    required message,
    required nextMessageInGroup,
  }) {
    var color = _user.id != message.author.id
        ? AppColor.chatSecondaryColor
        : AppColor.chatPrimaryColor;

    if (message.type == types.MessageType.image) {
      color = Colors.transparent;
    }

    return Bubble(
      color: color,
      margin: nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 6)
          : null,
      nip: nextMessageInGroup
          ? BubbleNip.no
          : _user.id != message.author.id
              ? BubbleNip.leftBottom
              : BubbleNip.rightBottom,
      child: child,
    );
  }

  Widget _customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    final theme = Theme.of(context);
    switch (message.metadata?["status"]) {
      case "resolved":
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColor.chatSecondaryColor,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              "issue_resolved".tr(),
              //"Issue resolved.\nOur team thanks you for helping us improve Autonomy.",
              textAlign: TextAlign.center,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.atlasWhiteBold14
                  : theme.textTheme.atlasWhiteBold16,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _status = "clickToReopen";
                });
              },
              style: theme.textButtonNoPadding,
              child: Text(
                "still_problem".tr(),
                //"Still experiencing the same problem?",
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.whitelinkStyle
                    : theme.textTheme.whitelinkStyle16,
              ),
            ),
          ]),
        );
      case "rating":
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColor.chatPrimaryColor,
          child: _ratingBar(message.metadata?["rating"]),
        );

      default:
        return const SizedBox();
    }
  }

  void _loadIssueDetails() async {
    if (_issueID == null) return;
    final issueDetails =
        await injector<CustomerSupportService>().getDetails(_issueID!);

    final parsedMessages = (await Future.wait(
            issueDetails.messages.map((e) => _convertChatMessage(e, null))))
        .expand((i) => i)
        .toList();

    if (mounted) {
      setState(() {
        String lastMessage = "";
        if (issueDetails.messages.isNotEmpty) {
          lastMessage = issueDetails.messages[0].message ?? "";
        }

        _status = issueDetails.issue.status;
        _isRated = issueDetails.issue.rating > 0 &&
            issueDetails.issue.status == "closed" &&
            (lastMessage.contains(RATING_MESSAGE_START) ||
                lastMessage.contains(STAR_RATING));
        _reportIssueType = issueDetails.issue.reportIssueType;
        _messages = parsedMessages;
      });
    }
  }

  bool _isRating(types.Message message) {
    final rating = message.metadata?["rating"];
    if (rating != null && rating != "" && rating > 0 && rating < 6) return true;
    return false;
  }

  Future _loadDrafts() async {
    if (_issueID == null) return;
    final drafts =
        await injector<CustomerSupportService>().getDrafts(_issueID!);
    final draftMessages =
        (await Future.wait(drafts.map((e) => _convertChatMessage(e, null))))
            .expand((i) => i)
            .toList();

    if (mounted) {
      setState(() {
        _draftMessages = draftMessages;
      });
    }
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

  Future _submit(String messageType, DraftCustomerSupportData data,
      {bool isRating = false}) async {
    log_util.log.info('[CS-Thread][start] _submit $messageType - $data');
    List<String> mutedMessages = [];
    if (_issueID == null) {
      messageType = CSMessageType.CreateIssue.rawValue;
      _issueID = "TEMP-${const Uuid().v4()}";

      final payload = widget.payload;
      if (payload is ExceptionErrorPayload) {
        final sentryID = payload.sentryID;
        if (sentryID.isNotEmpty) {
          mutedMessages.add(
              "[SENTRY REPORT $sentryID](https://sentry.io/organizations/bitmark-inc/issues/?query=$sentryID)");
        }

        if (payload.metadata.isNotEmpty) {
          mutedMessages.add("METADATA EXCEPTION: ${payload.metadata}");
        }
      }
    }
    if (isRating) {
      mutedMessages.add(MUTE_RATING_MESSAGE);
    }

    if (messageType == CSMessageType.PostMessage.rawValue &&
        _isRated == true &&
        _status == "closed") {
      data.text = "$RATING_MESSAGE_START${data.text}";
    }

    final draft = DraftCustomerSupport(
      uuid: const Uuid().v4(),
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
      _isRated = false;
    }

    await injector<CustomerSupportService>().draftMessage(draft);
    if (isRating) {
      final rating = getRating(data.text ?? "");
      if (rating > 0) {
        await injector<CustomerSupportService>().rateIssue(_issueID!, rating);
      }
    }
    setState(() {
      _sendIcon = "assets/images/sendMessage.svg";
      _forceAccountsViewRedraw = Object();
      if (isRating) _isRated = true;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    _submit(
      CSMessageType.PostMessage.rawValue,
      DraftCustomerSupportData(text: message.text),
    );
  }

  Future _addAppLogs() async {
    final file = await log_util.getLogFile();
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
          attachments: [LocalAttachment(fileName: filename, path: localPath)],
        ));

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _handleAtachmentPressed() {
    final theme = Theme.of(context);

    UIHelper.showDialog(
      context,
      "attach_file".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            style: theme.textButtonNoPadding,
            onPressed: () {
              _handleImageSelection();
              Navigator.of(context).pop();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('photo'.tr(), style: theme.primaryTextTheme.headline4),
            ),
          ),
          addDialogDivider(),
          TextButton(
            style: theme.textButtonNoPadding,
            onPressed: () async {
              await _addAppLogs();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('debug_log'.tr(),
                  style: theme.primaryTextTheme.headline4),
            ),
          ),
          const SizedBox(height: 40),
          Align(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("cancel".tr(), style: theme.primaryTextTheme.button),
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
      isDismissible: true,
    );
  }

  void _handleImageSelection() async {
    log_util.log.info('[_handleImageSelection] begin');
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
          attachments: attachments,
        ));
  }

  Future<List<types.Message>> _convertChatMessage(
      dynamic message, String? tempID) async {
    String id;
    types.User author;
    types.Status status;
    DateTime createdAt;
    String? text;
    int rating = 0;
    Map<String, dynamic> metadata = {};
    if (message is app.Message) {
      id = tempID ?? "${message.id}";
      author = message.from.contains("did:key") ? _user : _bitmark;
      status = types.Status.delivered;
      createdAt = message.timestamp;
      text = message.filteredMessage;
      rating = getRating(text);
      if (rating > 0) {
        metadata = {"rating": rating};
      }
      //
    } else if (message is DraftCustomerSupport) {
      id = message.uuid;
      author = _user;
      status = types.Status.sending;
      createdAt = message.createdAt;
      text = message.draftData.text;
      metadata = json.decode(message.data);
      rating = message.draftData.rating;
      if (rating > 0) {
        metadata["rating"] = rating;
      }
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
        metadata: metadata,
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
        uris.add("$storedDirectory/${attachment.title}");
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
          id: '$id$i',
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
          id: '$id$i',
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

  int getRating(String text) {
    if (text.startsWith(STAR_RATING)){
      final rating = int.tryParse(text.replacePrefix(STAR_RATING, ""));
      if (rating != null && rating > 0 && rating <= 5) {
        return rating;
      }
    }
    return 0;
  }

  DefaultChatTheme get _chatTheme {
    final theme = Theme.of(context);
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      inputPadding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
      backgroundColor: Colors.transparent,
      inputBackgroundColor: theme.colorScheme.primary,
      inputTextStyle: theme.textTheme.bodyText1!,
      inputTextColor: theme.colorScheme.secondary,
      attachmentButtonIcon: SvgPicture.asset(
        "assets/images/joinFile.svg",
        color: theme.colorScheme.secondary,
      ),
      inputBorderRadius: BorderRadius.zero,
      sendButtonIcon: SvgPicture.asset(
        _sendIcon,
      ),
      inputTextCursorColor: theme.colorScheme.secondary,
      emptyChatPlaceholderTextStyle: theme.textTheme.headline4!
          .copyWith(color: AppColor.secondarySpanishGrey),
      dateDividerMargin: const EdgeInsets.symmetric(vertical: 12),
      dateDividerTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.dateDividerTextStyle
          : theme.textTheme.dateDividerTextStyle14,
      primaryColor: Colors.transparent,
      sentMessageBodyTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.sentMessageBodyTextStyle
          : theme.textTheme.sentMessageBodyTextStyle16,
      secondaryColor: AppColor.chatSecondaryColor,
      receivedMessageBodyTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.receivedMessageBodyTextStyle
          : theme.textTheme.receivedMessageBodyTextStyle16,
      receivedMessageDocumentIconColor: theme.colorScheme.secondary,
      sentMessageDocumentIconColor: theme.colorScheme.secondary,
      documentIcon: Image.asset(
        "assets/images/chatFileIcon.png",
        width: 20,
      ),
      sentMessageCaptionTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.sentMessageCaptionTextStyle
          : theme.textTheme.sentMessageCaptionTextStyle16,
      receivedMessageCaptionTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.receivedMessageCaptionTextStyle
          : theme.textTheme.receivedMessageCaptionTextStyle16,
      sendingIcon: Container(
        width: 16,
        height: 12,
        padding: const EdgeInsets.only(left: 3),
        child: const CircularProgressIndicator(
          color: AppColor.secondarySpanishGrey,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class MyRatingBar extends StatefulWidget {
  MyRatingBar({Key? key, required this.submit}) : super(key: key);
  Future<dynamic> Function(String messageType, DraftCustomerSupportData data,
      {bool isRating}) submit;

  @override
  _MyRatingBar createState() => _MyRatingBar();
}

class _MyRatingBar extends State<MyRatingBar> {
  String customerRating = "";
  int ratingInt = 0;
  Widget sendButtonRating = SvgPicture.asset("assets/images/sendMessage.svg");

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
      color: AppColor.primaryBlack,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RatingBar.builder(
            minRating: 1,
            itemSize: 24,
            itemPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: AppColor.white,
            ),
            unratedColor: AppColor.chatSecondaryColor,
            onRatingUpdate: _updateRating,
          ),
          const SizedBox(width: 40),
          IconButton(onPressed: _sendButtonOnPress, icon: sendButtonRating),
          const SizedBox(width: 10)
        ],
      ),
    );
  }

  _updateRating(double rating) {
    ratingInt = rating.toInt();
    customerRating = _convertRatingToText(ratingInt);
    setState(() {
      sendButtonRating =
          SvgPicture.asset("assets/images/sendMessageFilled.svg");
    });
  }

  _sendButtonOnPress() async {
    if (ratingInt < 1) return;
    widget.submit(CSMessageType.PostMessage.rawValue,
        DraftCustomerSupportData(text: customerRating, rating: ratingInt),
        isRating: true);
  }

  String _convertRatingToText(int rating) {
    if (rating > 0) return "$STAR_RATING${rating.toString()}";

    return "";
  }
}
