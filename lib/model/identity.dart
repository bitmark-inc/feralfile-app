import 'package:autonomy_flutter/service/hive_store_service.dart';

class IndexerIdentity implements HiveObject {
  IndexerIdentity(this.accountNumber, this.blockchain, this.name);

  String accountNumber;
  String blockchain;
  String name;

  DateTime queriedAt = DateTime.now();

  @override
  String get hiveId =>
      accountNumber; // ObjectBox requires an id, but we don't use it
}
