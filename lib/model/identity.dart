import 'package:autonomy_flutter/service/hive_store_service.dart'
    as hive_store_service;
import 'package:hive_flutter/adapters.dart';

class IndexerIdentity implements hive_store_service.HiveObject {
  IndexerIdentity(this.accountNumber, this.blockchain, this.name);

  String accountNumber;
  String blockchain;
  String name;

  DateTime queriedAt = DateTime.now();

  @override
  String get hiveId =>
      accountNumber; // ObjectBox requires an id, but we don't use it
}

class IndexerIdentityAdapter extends TypeAdapter<IndexerIdentity> {
  @override
  final int typeId = hive_store_service.HiveStoreId.indexerIdentity.typeId;

  @override
  IndexerIdentity read(BinaryReader reader) {
    return IndexerIdentity(
      reader.readString(),
      reader.readString(),
      reader.readString(),
    )..queriedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
  }

  @override
  void write(BinaryWriter writer, IndexerIdentity obj) {
    writer
      ..writeString(obj.accountNumber)
      ..writeString(obj.blockchain)
      ..writeString(obj.name)
      ..writeInt(obj.queriedAt.millisecondsSinceEpoch);
  }
}
