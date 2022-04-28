import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart' as app;
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:bubble/bubble.dart';
import 'package:autonomy_flutter/util/log.dart' as logUtil;

class SupportThreadPage extends StatefulWidget {
  final String reportIssueType;
  final String? issueID;

  const SupportThreadPage({
    Key? key,
    required this.reportIssueType,
    this.issueID,
  }) : super(key: key);

  @override
  _SupportThreadPageState createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends State<SupportThreadPage> {
  List<types.Message> _messages = [];
  List<types.Message> _pendingMessages = [];
  List<app.SendMessage> _pendingSendMessages = [];
  bool _isPostMessageRunning = false;
  final _user = const types.User(id: 'user');
  final _bitmark = const types.User(id: 'bitmark');
  String _reportIssueType = '';
  String _status = '';
  String? _issueID;
  var _forceAccountsViewRedraw;
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
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .addListener(_loadIssueDetails);
    _reportIssueType = widget.reportIssueType;
    _issueID = widget.issueID;
    memoryValues.viewingSupportThreadIssueID = _issueID;
    _forceAccountsViewRedraw = Object();
    super.initState();

    if (_issueID != null) {
      _loadIssueDetails();
    }
  }

  @override
  void dispose() {
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .removeListener(_loadIssueDetails);
    memoryValues.viewingSupportThreadIssueID = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<types.Message> messages = (_pendingMessages + _messages);
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

  void _handleSendPressed(types.PartialText message) async {
    _pendingSendMessages.insert(
      0,
      app.SendMessage(
          id: const Uuid().v4(),
          message: message.text,
          attachments: [],
          timestamp: DateTime.now()),
    );

    await _convertPendingChatMessages();
    setState(() {
      _sendIcon = "assets/images/sendMessage.svg";
    });
    _postMessageToServer();
  }

  Future _addAppLogs() async {
    final logFilePath = await logUtil.getLatestLogFile();
    File file = File(logFilePath);
    final bytes = await file.readAsBytes();
    final log = base64Encode(bytes);
    final fileName = logFilePath.split('/').last;

    _pendingSendMessages.add(app.SendMessage(
      id: const Uuid().v4(),
      message: '',
      attachments: [
        app.SendAttachment(
          data: log,
          title: "${bytes.length}_$fileName",
          contentType: 'file',
        ),
      ],
      timestamp: DateTime.now(),
    ));
  }

  void _handleAtachmentPressed() {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    UIHelper.showDialog(
      context,
      "Join file",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            style: textButtonNoPadding,
            onPressed: () {
              Navigator.of(context).pop();
              _handleImageSelection();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Upload photo', style: theme.textTheme.headline4),
            ),
          ),
          addDialogDivider(),
          TextButton(
            style: textButtonNoPadding,
            onPressed: () async {
              final accountAuditLogsBytes =
                  await injector<AuditService>().export();
              final accountLogTitle =
                  'account_audit-${DateTime.now().microsecondsSinceEpoch}.logs';

              _pendingSendMessages.insert(
                0,
                app.SendMessage(
                    id: const Uuid().v4(),
                    message: '',
                    attachments: [
                      app.SendAttachment(
                        data: base64Encode(accountAuditLogsBytes),
                        title: "${accountAuditLogsBytes.length}_" +
                            accountLogTitle,
                        contentType: 'file',
                      ),
                    ],
                    timestamp: DateTime.now()),
              );

              await _convertPendingChatMessages();
              setState(() {
                _forceAccountsViewRedraw = Object();
              });
              Navigator.pop(context);
              _postMessageToServer();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Attach accounts log', style: theme.textTheme.headline4),
            ),
          ),
          addDialogDivider(),
          TextButton(
            style: textButtonNoPadding,
            onPressed: () async {
              await _addAppLogs();
              await _convertPendingChatMessages();
              setState(() {
                _forceAccountsViewRedraw = Object();
              });
              Navigator.pop(context);
              _postMessageToServer();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Attach app log', style: theme.textTheme.headline4),
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
    final result = await ImagePicker().pickMultiImage();

    if (result == null) return;

    final attachments = await Future.wait(result.map((element) async {
      final bytes = await element.readAsBytes();
      return app.SendAttachment(
        data: base64Encode(bytes),
        title: "${bytes.length}_${element.name}",
        path: element.path,
        contentType: 'image',
      );
    }));

    _pendingSendMessages.insert(
      0,
      app.SendMessage(
          id: const Uuid().v4(),
          message: '',
          attachments: attachments,
          timestamp: DateTime.now()),
    );

    await _convertPendingChatMessages();
    setState(() {
      _forceAccountsViewRedraw = Object();
    });

    _postMessageToServer();
  }

  Future _convertPendingChatMessages() async {
    final _parsedSendMessages = (await Future.wait(
            _pendingSendMessages.map((e) => _convertChatMessage(e, null))))
        .expand((i) => i)
        .toList();

    _pendingMessages = _parsedSendMessages;
  }

  Future<List<types.Message>> _convertChatMessage(
      dynamic message, String? tempID) async {
    late var id, author, status, createdAt, text;

    if (message is app.Message) {
      id = tempID ?? "${message.id}";
      author = message.from.contains("did:key") ? _user : _bitmark;
      status = types.Status.delivered;
      createdAt = message.timestamp;
      text = message.message;
      //
    } else if (message is app.SendMessage) {
      id = message.id;
      author = _user;
      status = types.Status.sending;
      createdAt = message.timestamp;
      text = message.message;
      //
    } else {
      return [];
    }

    if (text is String && text.isNotEmpty && text != EMPTY_ISSUE_MESSAGE) {
      return [
        types.TextMessage(
          id: id,
          author: author,
          createdAt: createdAt.millisecondsSinceEpoch,
          text: text,
          status: status,
          showStatus: true,
        )
      ];
    } else {
      List<types.Message> messages = [];
      final storedDirectory =
          await injector<CustomerSupportService>().getStoredDirectory();
      List<String> titles = [];
      List<String> uris = [];
      List<String> contentTypes = [];

      if (message is app.Message) {
        for (var attachment in message.attachments) {
          titles.add(attachment.title);
          uris.add(storedDirectory + "/" + attachment.name);
          contentTypes.add(attachment.contentType);
        }
        //
      } else if (message is app.SendMessage) {
        for (var attachment in message.attachments) {
          titles.add(attachment.title);
          uris.add(attachment.path);
          contentTypes.add(attachment.contentType);
        }
      }

      for (var i = 0; i < titles.length; i += 1) {
        if (contentTypes[i].contains("image")) {
          messages.add(types.ImageMessage(
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
          messages.add(types.FileMessage(
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

      return messages;
    }
  }

  void _postMessageToServer() async {
    // return;
    if (_isPostMessageRunning || _pendingSendMessages.length == 0) return;
    final message = _pendingSendMessages.last;
    _isPostMessageRunning = true;
    app.Message postedMessage;

    if (_issueID == null) {
      final result = await injector<CustomerSupportService>().createIssue(
        widget.reportIssueType,
        message.message,
        message.attachments,
      );
      _issueID = result.issueID;
      memoryValues.viewingSupportThreadIssueID = _issueID;
      injector<CustomerSupportService>()
          .triggerReloadMessages
          .addListener(_loadIssueDetails);
      postedMessage = result.message;

      //
    } else {
      if (_status == 'closed' || _status == 'clickToReopen') {
        setState(() {
          _status = "reopening";
        });
        await injector<CustomerSupportService>().reopen(_issueID!);
      }

      final result = await injector<CustomerSupportService>()
          .commentIssue(_issueID!, message.message, message.attachments);
      postedMessage = result.message;
    }

    final _pendingSendMessage = _pendingSendMessages.removeLast();
    if (message.attachments.length > 0 &&
        message.attachments.length == postedMessage.attachments.length) {
      for (var i = 0; i < message.attachments.length; i += 1) {
        final attachment = postedMessage.attachments[i];

        // only local backup image for now
        if (attachment.contentType.contains('image')) {
          await injector<CustomerSupportService>().storeFile(
              postedMessage.attachments[i].name,
              base64Decode(message.attachments[i].data));
        }
      }
    }

    await _convertPendingChatMessages();
    final newMessages =
        await _convertChatMessage(postedMessage, _pendingSendMessage.id);

    setState(() {
      _messages.insertAll(0, newMessages);
    });

    _isPostMessageRunning = false;
    _postMessageToServer();
  }

  DefaultChatTheme get _chatTheme {
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      inputPadding: EdgeInsets.fromLTRB(0, 24, 0, 20),
      inputMargin: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      inputBackgroundColor: Colors.black,
      inputTextStyle: TextStyle(
          fontSize: 16,
          fontFamily: "AtlasGrotesk-Medium",
          fontWeight: FontWeight.w500,
          height: 1.377),
      inputTextColor: Colors.white,
      attachmentButtonIcon: SvgPicture.asset("assets/images/joinFile.svg"),
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
        "assets/images/iconFile.png",
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
