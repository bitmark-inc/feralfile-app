//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unused_field

import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart' as app;
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/claim/airdrop/claim_airdrop_page.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/announcement_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart' as log_util;
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
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
import 'package:nft_collection/models/asset_token.dart';
import 'package:uuid/uuid.dart';

import '../../util/datetime_ext.dart';

abstract class SupportThreadPayload {
  AnnouncementLocal? get announcement;
}

class NewIssuePayload extends SupportThreadPayload {
  final String reportIssueType;
  @override
  final AnnouncementLocal? announcement;

  NewIssuePayload({
    required this.reportIssueType,
    this.announcement,
  });
}

class DetailIssuePayload extends SupportThreadPayload {
  final String reportIssueType;
  final String issueID;
  final String status;
  final bool isRated;
  @override
  final AnnouncementLocal? announcement;

  DetailIssuePayload(
      {required this.reportIssueType,
      required this.issueID,
      this.status = "",
      this.isRated = false,
      this.announcement});
}

class ExceptionErrorPayload extends SupportThreadPayload {
  final String sentryID;
  final String metadata;
  @override
  final AnnouncementLocal? announcement;

  ExceptionErrorPayload({
    required this.sentryID,
    required this.metadata,
    this.announcement,
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

class _SupportThreadPageState extends State<SupportThreadPage>
    with AfterLayoutMixin<SupportThreadPage> {
  String _reportIssueType = '';
  String? _issueID;

  bool isCustomerSupportAvailable = true;
  List<types.Message> _messages = [];
  List<types.Message> _draftMessages = [];
  final _user = const types.User(id: 'user');
  final _bitmark = const types.User(id: 'bitmark');

  String _status = '';
  bool _isRated = false;
  bool _isFileAttached = false;
  Pair<String, List<int>>? _debugLog;
  late bool loading;

  late Object _forceAccountsViewRedraw;
  var _sendIcon = "assets/images/sendMessage.svg";
  final _introMessengerID = const Uuid().v4();
  final _resolvedMessengerID = const Uuid().v4();
  final _askRatingMessengerID = const Uuid().v4();
  final _askReviewMessengerID = const Uuid().v4();
  final _announcementMessengerID = const Uuid().v4();
  final _customerSupportService = injector<CustomerSupportService>();
  final _airdropService = injector<AirdropService>();
  final _feralFileService = injector<FeralFileService>();

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

  types.CustomMessage get _askRatingMessenger => types.CustomMessage(
        author: _bitmark,
        id: _askRatingMessengerID,
        metadata: {"status": "rateIssue", "content": "rate_issue".tr()},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  types.CustomMessage get _askReviewMessenger => types.CustomMessage(
        author: _bitmark,
        id: _askReviewMessengerID,
        metadata: {"status": "careToShare", "content": "care_to_share".tr()},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  types.CustomMessage get _announcementMessenger => types.CustomMessage(
        id: _announcementMessengerID,
        author: _bitmark,
        metadata: const {"status": "announcement"},
      );

  @override
  void initState() {
    _fetchCustomerSupportAvailability();
    loading = false;
    injector<CustomerSupportService>().processMessages();
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .addListener(_loadIssueDetails);

    _customerSupportService.customerSupportUpdate
        .addListener(_loadCustomerSupportUpdates);

    final payload = widget.payload;
    if (payload is NewIssuePayload) {
      _reportIssueType = payload.reportIssueType;
      if (_reportIssueType == ReportIssueType.Bug) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _askForAttachCrashLog(context, onConfirm: (attachCrashLog) {
            if (attachCrashLog) {
              _addDebugLog();
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
      _issueID = _customerSupportService.tempIssueIDMap[payload.issueID] ??
          payload.issueID;
    } else if (payload is ExceptionErrorPayload) {
      _reportIssueType = ReportIssueType.Exception;
      Future.delayed(const Duration(milliseconds: 300), () {
        _askForAttachCrashLog(context, onConfirm: (attachCrashLog) {
          if (attachCrashLog) {
            _addDebugLog();
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
  void afterFirstLayout(BuildContext context) {
    final payload = widget.payload;
    if (payload.announcement != null && payload.announcement!.unread) {
      _customerSupportService
          .markAnnouncementAsRead(payload.announcement!.announcementContextId);
      _callMixpanelReadAnnouncementEvent(payload.announcement!);
    }
  }

  _fetchCustomerSupportAvailability() async {
    final device = DeviceInfo.instance;
    final isAvailable = await device.isSupportOS();
    setState(() {
      isCustomerSupportAvailable = isAvailable;
    });
  }

  Future<void> _addDebugLog() async {
    Navigator.of(context).pop();

    const fileMaxSize = 1024 * 1024;
    final file = await log_util.getLogFile();
    final bytes = await file.readAsBytes();
    final auditBytes = await injector<AuditService>().export();
    var combinedBytes = bytes + auditBytes;
    if (combinedBytes.length > fileMaxSize) {
      combinedBytes = combinedBytes.sublist(combinedBytes.length - fileMaxSize);
    }
    final filename =
        "${combinedBytes.length}_${DateTime.now().microsecondsSinceEpoch}.logs";
    _debugLog = Pair(filename, combinedBytes);
    setState(() {
      _isFileAttached = true;
    });
  }

  void _callMixpanelReadAnnouncementEvent(AnnouncementLocal announcement) {
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent(
      MixpanelEvent.readAnnouncement,
      data: {
        "id": announcement.announcementContextId,
        "type": announcement.type,
        "title": announcement.title,
      },
    );
  }

  @override
  void dispose() {
    _customerSupportService.triggerReloadMessages
        .removeListener(_loadIssueDetails);
    _customerSupportService.customerSupportUpdate
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
          Text(
            "ask_attach_crash".tr(),
            //"Would you like to attach a crash log with your support request? The crash log is anonymous and will help our engineers identify the issue.",
            style: theme.primaryTextTheme.ppMori400White14,
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: "attach_crash_logH".tr(),
            onTap: () => onConfirm(true),
          ),
          const SizedBox(height: 10),
          OutlineButton(
            text: "conti_no_crash_log".tr(),
            onTap: () => onConfirm(false),
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
    if (widget.payload.announcement != null) {
      messages.add(_announcementMessenger);
    } else if (_issueID == null || messages.isNotEmpty) {
      messages.add(_introMessenger);
    }

    return Scaffold(
        appBar: getBackAppBar(
          context,
          title: ReportIssueType.toTitle(_reportIssueType),
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
              onSendPressed: _handleSendPressed,
              user: _user,
              listBottomWidget:
                  (widget.payload.announcement?.isMemento6 == true)
                      ? FutureBuilder(
                          future: _airdropService
                              .getTokenByContract(momaMementoContractAddresses),
                          builder: (context, snapshot) {
                            final token = snapshot.data as AssetToken?;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 18, right: 18, bottom: 15),
                              child: PrimaryButton(
                                text: "claim_your_gift".tr(),
                                enabled: !loading && token != null,
                                isProcessing: loading,
                                onTap: () async {
                                  if (token == null) return;
                                  setState(() {
                                    loading = true;
                                  });
                                  try {
                                    final response = await _airdropService
                                        .claimRequestGift(token);
                                    final series = await _feralFileService
                                        .getSeries(response.seriesID);
                                    if (!mounted) return;
                                    Navigator.of(context).pushNamed(
                                        AppRouter.claimAirdropPage,
                                        arguments: ClaimTokenPagePayload(
                                            claimID: response.claimID,
                                            series: series,
                                            shareCode: ''));
                                  } catch (e) {
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                  setState(() {
                                    loading = false;
                                  });
                                },
                              ),
                            );
                          })
                      : null,
              customBottomWidget: !isCustomerSupportAvailable
                  ? const SizedBox()
                  : _isRated == false && _status == 'closed'
                      ? MyRatingBar(
                          submit: (String messageType,
                                  DraftCustomerSupportData data,
                                  {bool isRating = false}) =>
                              _submit(messageType, data, isRating: isRating))
                      : Column(
                          children: [
                            if (_isFileAttached) debugLogView(),
                            Input(
                              onSendPressed: _handleSendPressed,
                              onAttachmentPressed: _handleAttachmentPressed,
                              options: _inputOption(),
                            ),
                          ],
                        ),
            )));
  }

  InputOptions _inputOption() {
    return InputOptions(
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
        });
  }

  Widget debugLogView() {
    if (_debugLog == null) return const SizedBox();
    final debugLog = _debugLog!;
    final theme = Theme.of(context);
    final fileSize = debugLog.second.length;
    final fileSizeInMB = fileSize / (1024 * 1024);
    return Container(
      color: AppColor.auGreyBackground,
      padding: const EdgeInsets.fromLTRB(25, 5, 25, 5),
      child: Row(
        children: [
          Text(
            debugLog.first.split("_").last,
            style: theme.primaryTextTheme.ppMori400White14
                .copyWith(color: AppColor.auSuperTeal),
          ),
          const SizedBox(width: 5),
          Text(
            "(${fileSizeInMB.toStringAsFixed(2)} MB)",
            style: theme.primaryTextTheme.ppMori400White14
                .copyWith(color: AppColor.auQuickSilver),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFileAttached = false;
                _debugLog = null;
              });
            },
            child: SvgPicture.asset(
              "assets/images/iconClose.svg",
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
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
        color: AppColor.white,
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
    final theme = Theme.of(context);
    var color = _user.id != message.author.id
        ? AppColor.auSuperTeal
        : AppColor.primaryBlack;

    if (message.type == types.MessageType.image) {
      color = Colors.transparent;
    }
    bool isError = false;
    String uuid = "";
    if (message is types.Message) {
      if (message.status == types.Status.error) {
        isError = true;
        uuid = message.id;
      }
    }
    Color orangeRust = const Color(0xffA1200A);

    return isError
        ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Bubble(
                        color: color,
                        radius: const Radius.circular(10),
                        nipWidth: 0.1,
                        nipRadius: 0,
                        nip: _user.id != message.author.id
                            ? BubbleNip.leftBottom
                            : BubbleNip.rightBottom,
                        child: child,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _customerSupportService.removeErrorMessage(uuid);
                        _loadDrafts();
                        _customerSupportService.processMessages();
                        Future.delayed(const Duration(seconds: 5), () {
                          _loadDrafts();
                        });
                      },
                      child: Text(
                        "retry".tr(),
                        style: theme.textTheme.ppMori400Black12
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                    Text(
                      "・",
                      style: theme.textTheme.ppMori400Black12,
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _customerSupportService.removeErrorMessage(uuid,
                            isDelete: true);
                        await _loadDrafts();
                        if (_draftMessages.isEmpty && _messages.isEmpty) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        "delete".tr(),
                        style: theme.textTheme.ppMori400Black12
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "failed_to_send".tr(),
                      style: theme.textTheme.ppMori400Black12
                          .copyWith(color: orangeRust),
                    ),
                  ],
                ),
              ],
            ),
          )
        : Bubble(
            color: color,
            radius: const Radius.circular(10),
            nipWidth: 0.1,
            nipRadius: 0,
            nip: _user.id != message.author.id
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
          color: AppColor.auSuperTeal,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "issue_resolved_".tr(),
              textAlign: TextAlign.start,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori700Black14
                  : theme.textTheme.ppMori700Black16,
            ),
            const SizedBox(height: 10),
            Text(
              "our_team_thank".tr(),
              textAlign: TextAlign.start,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori400Black14
                  : theme.textTheme.ppMori400Black16,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                if (_status == "close") {
                  setState(() {
                    _status = "clickToReopen";
                  });
                }
              },
              style: theme.textButtonNoPadding,
              child: Text(
                "still_problem".tr(),
                //"Still experiencing the same problem?",
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.linkStyle14
                        .copyWith(fontFamily: AppTheme.ppMori)
                    : theme.textTheme.linkStyle16
                        .copyWith(fontFamily: AppTheme.ppMori),
              ),
            ),
          ]),
        );
      case "rating":
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColor.primaryBlack,
          child: _ratingBar(message.metadata?["rating"]),
        );
      case "careToShare":
      case "rateIssue":
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColor.auSuperTeal,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              message.metadata?["content"],
              textAlign: TextAlign.start,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori700Black14
                  : theme.textTheme.ppMori700Black16,
            ),
          ]),
        );
      case "announcement":
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColor.auSuperTeal,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.payload.announcement!.title.isNotEmpty) ...[
              Text(
                widget.payload.announcement!.title,
                textAlign: TextAlign.start,
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.ppMori700Black14
                    : theme.textTheme.ppMori700Black16,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              widget.payload.announcement!.body,
              textAlign: TextAlign.start,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori400Black14
                  : theme.textTheme.ppMori400Black16,
            ),
          ]),
        );
      default:
        return const SizedBox();
    }
  }

  void _loadIssueDetails() async {
    if (_issueID == null) return;
    final issueDetails = await _customerSupportService.getDetails(_issueID!);
    if (widget.payload.announcement != null && issueDetails.issue.unread > 0) {
      _callMixpanelReadAnnouncementEvent(widget.payload.announcement!);
    }

    final parsedMessages = (await Future.wait(
            issueDetails.messages.map((e) => _convertChatMessage(e, null))))
        .expand((i) => i)
        .toList();

    if (mounted) {
      setState(() {
        String lastMessage = "";
        if (issueDetails.messages.isNotEmpty) {
          lastMessage = issueDetails.messages[0].message;
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
    final drafts = await _customerSupportService.getDrafts(_issueID!);
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
    final update = _customerSupportService.customerSupportUpdate.value;
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
      if (payload.announcement != null) {
        final metricClient = injector.get<MetricClientService>();
        final announcement = payload.announcement!;
        metricClient.addEvent(
          MixpanelEvent.replyAnnouncement,
          data: {
            "id": announcement.announcementContextId,
            "type": announcement.type,
            "title": announcement.title,
          },
        );
        data.announcementId = announcement.announcementContextId;
      }

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
      await _customerSupportService.reopen(_issueID!);
      _status = "open";
      _isRated = false;
    }

    await _customerSupportService.draftMessage(draft);
    if (isRating) {
      final rating = getRating(data.text ?? "");
      if (rating > 0) {
        await _customerSupportService.rateIssue(_issueID!, rating);
      }
    }
    setState(() {
      _sendIcon = "assets/images/sendMessage.svg";
      _forceAccountsViewRedraw = Object();
      if (isRating) _isRated = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      _loadDrafts();
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_isFileAttached) {
      _addAppLogs(message);
    } else {
      _submit(
        CSMessageType.PostMessage.rawValue,
        DraftCustomerSupportData(
            text: message.text,
            announcementId: widget.payload.announcement?.announcementContextId),
      );
    }
  }

  Future _addAppLogs(types.PartialText message) async {
    if (_debugLog == null) return;
    final filename = _debugLog!.first;
    final combinedBytes = _debugLog!.second;

    final localPath =
        await _customerSupportService.storeFile(filename, combinedBytes);

    await _submit(
      CSMessageType.PostLogs.rawValue,
      DraftCustomerSupportData(
        text: message.text,
        attachments: [LocalAttachment(fileName: filename, path: localPath)],
        announcementId: widget.payload.announcement?.announcementContextId,
      ),
    );
    setState(() {
      _isFileAttached = false;
    });
  }

  void _handleAttachmentPressed() {
    if (_isFileAttached) {
      return;
    }
    UIHelper.showDialog(
      context,
      "attach_file".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryButton(
            onTap: () {
              _handleImageSelection();
              Navigator.of(context).pop();
            },
            text: 'photo'.tr(),
          ),
          const SizedBox(
            height: 10,
          ),
          PrimaryButton(
            onTap: () {
              _addDebugLog();
            },
            text: 'debug_log'.tr(),
          ),
          const SizedBox(height: 10),
          OutlineButton(
            onTap: () => Navigator.of(context).pop(),
            text: "cancel_dialog".tr(),
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

    final attachments = await Future.wait(result.map((element) async {
      final bytes = await element.readAsBytes();
      final fileName = "${bytes.length}_${element.name}";
      final localPath =
          await _customerSupportService.storeFile(fileName, bytes);
      return LocalAttachment(path: localPath, fileName: fileName);
    }));

    await _submit(
      CSMessageType.PostPhotos.rawValue,
      DraftCustomerSupportData(
        attachments: attachments,
        announcementId: widget.payload.announcement?.announcementContextId,
      ),
    );
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
      final errorMessages = _customerSupportService.errorMessages;
      status = (errorMessages != null && errorMessages.contains(id))
          ? types.Status.error
          : types.Status.sending;
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

    final storedDirectory = await _customerSupportService.getStoredDirectory();
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
          id: '$id${titles[i]}',
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
        result.insert(
            0,
            types.FileMessage(
              id: '$id${sizeAndRealTitle[1]}',
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
    if (text.startsWith(STAR_RATING)) {
      final rating = int.tryParse(text.replacePrefix(STAR_RATING, ""));
      if (rating != null && rating > 0 && rating <= 5) {
        return rating;
      }
    }
    return 0;
  }

  DefaultChatTheme get _chatTheme {
    final theme = Theme.of(context);
    bool isKeyboardShowing = MediaQuery.of(context).viewInsets.vertical > 0;
    final inputPadding = isKeyboardShowing
        ? const EdgeInsets.fromLTRB(0, 20, 0, 20)
        : const EdgeInsets.fromLTRB(0, 10, 0, 32);
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      errorIcon: const SizedBox(),
      inputPadding: inputPadding,
      backgroundColor: Colors.transparent,
      inputBackgroundColor: theme.colorScheme.primary,
      inputTextStyle: theme.textTheme.ppMori400White14,
      inputTextColor: theme.colorScheme.secondary,
      attachmentButtonIcon: SvgPicture.asset(
        "assets/images/joinFile.svg",
        colorFilter: ColorFilter.mode(
            _isFileAttached
                ? AppColor.disabledColor
                : theme.colorScheme.secondary,
            BlendMode.srcIn),
      ),
      inputBorderRadius: BorderRadius.zero,
      sendButtonIcon: SvgPicture.asset(
        _sendIcon,
      ),
      inputTextCursorColor: theme.colorScheme.secondary,
      emptyChatPlaceholderTextStyle: theme.textTheme.ppMori400White14
          .copyWith(color: AppColor.auQuickSilver),
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
      receivedMessageDocumentIconColor: Colors.transparent,
      sentMessageDocumentIconColor: Colors.transparent,
      documentIcon: SvgPicture.asset(
        "assets/images/bug_icon.svg",
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
  const MyRatingBar({Key? key, required this.submit}) : super(key: key);
  final Future<dynamic> Function(
          String messageType, DraftCustomerSupportData data, {bool isRating})
      submit;

  @override
  State<MyRatingBar> createState() => _MyRatingBarState();
}

class _MyRatingBarState extends State<MyRatingBar> {
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
