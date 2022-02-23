import 'package:floor/floor.dart';
import 'package:libauk_dart/libauk_dart.dart';

class DateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) {
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int encode(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

@entity
class Persona {
  @primaryKey
  String uuid;
  String name;
  DateTime createdAt;

  Persona({
    required this.uuid,
    required this.name,
    required this.createdAt,
  });

  Persona.newPersona({required this.uuid, this.name = "", DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Persona copyWith({
    String? name,
    DateTime? createdAt,
  }) {
    return Persona(
        uuid: this.uuid,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt);
  }

  WalletStorage wallet() {
    return LibAukDart.getWallet(uuid);
  }
}
