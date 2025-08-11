import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/model/draft_customer_support.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:flutter/src/foundation/change_notifier.dart';

class MockCustomerSupportService implements CustomerSupportService {

  @override
  // getChatThreads
  Future<List<ChatThread>> getChatThreads() {
    return Future.value([]);
  }

  @override
  Future<void> clear() {
    // TODO: implement clear
    throw UnimplementedError();
  }

  @override
  // TODO: implement customerSupportUpdate
  ValueNotifier<CustomerSupportUpdate?> get customerSupportUpdate =>
      throw UnimplementedError();

  @override
  Future draftMessage(DraftCustomerSupport draft) {
    // TODO: implement draftMessage
    throw UnimplementedError();
  }

  @override
  // TODO: implement errorMessages
  List<String>? get errorMessages => throw UnimplementedError();

  @override
  Future<IssueDetails> getDetails(String issueID) {
    // TODO: implement getDetails
    throw UnimplementedError();
  }

  @override
  Future<List<DraftCustomerSupport>> getDrafts(String issueID) {
    // TODO: implement getDrafts
    throw UnimplementedError();
  }

  @override
  Future<String> getStoredDirectory() {
    // TODO: implement getStoredDirectory
    throw UnimplementedError();
  }

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  // TODO: implement numberOfIssuesInfo
  ValueNotifier<List<int>?> get numberOfIssuesInfo =>
      ValueNotifier<List<int>?>(null);

  @override
  Future processMessages() {
    // TODO: implement processMessages
    throw UnimplementedError();
  }

  @override
  Future rateIssue(String issueID, int rating) {
    // TODO: implement rateIssue
    throw UnimplementedError();
  }

  @override
  Future<void> removeErrorMessage(String uuid, {bool isDelete = false}) {
    // TODO: implement removeErrorMessage
    throw UnimplementedError();
  }

  @override
  Future reopen(String issueID) {
    // TODO: implement reopen
    throw UnimplementedError();
  }

  @override
  void sendMessageFail(String uuid) {
    // TODO: implement sendMessageFail
  }

  @override
  Future<String> storeFile(String filename, List<int> bytes) {
    // TODO: implement storeFile
    throw UnimplementedError();
  }

  @override
  // TODO: implement tempIssueIDMap
  Map<String, String> get tempIssueIDMap => throw UnimplementedError();

  @override
  // TODO: implement triggerReloadMessages
  ValueNotifier<int> get triggerReloadMessages => throw UnimplementedError();
}
