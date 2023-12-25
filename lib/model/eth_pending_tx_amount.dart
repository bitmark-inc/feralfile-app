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
