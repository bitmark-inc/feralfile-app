import 'package:hive/hive.dart';

class EthereumPendingTxAmount {
  EthereumPendingTxAmount({
    required this.txHash,
    this.deductAmount,
    this.addAmount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String txHash;
  final BigInt? deductAmount;
  final BigInt? addAmount;
  final DateTime createdAt;

  static const _expiredDuration = Duration(minutes: 15);

  BigInt get getDeductAmount =>
      (deductAmount ?? BigInt.zero) - (addAmount ?? BigInt.zero);

  bool get isExpired => DateTime.now().difference(createdAt) > _expiredDuration;
}

class EthereumPendingTxAmountAdapter
    extends TypeAdapter<EthereumPendingTxAmount> {
  @override
  final typeId = 1; // You can choose any unique positive integer

  @override
  EthereumPendingTxAmount read(BinaryReader reader) => EthereumPendingTxAmount(
        txHash: reader.read(),
        deductAmount: reader.read(),
        addAmount: reader.read(),
        createdAt: reader.read(),
      );

  @override
  void write(BinaryWriter writer, EthereumPendingTxAmount obj) {
    writer
      ..write(obj.txHash)
      ..write(obj.deductAmount)
      ..write(obj.addAmount)
      ..write(obj.createdAt);
  }
}

class EthereumPendingTxListAdapter
    extends TypeAdapter<List<EthereumPendingTxAmount>> {
  @override
  final int typeId = 2; // You can choose any unique positive integer

  @override
  List<EthereumPendingTxAmount> read(BinaryReader reader) {
    final length = reader.readUint32();
    return List.generate(
        length, (index) => EthereumPendingTxAmountAdapter().read(reader));
  }

  @override
  void write(BinaryWriter writer, List<EthereumPendingTxAmount> obj) {
    writer.writeUint32(obj.length);
    for (final item in obj) {
      EthereumPendingTxAmountAdapter().write(writer, item);
    }
  }
}
