import 'package:floor/floor.dart';

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
class Identity {
  @primaryKey
  String accountNumber;
  String blockchain;
  String name;
  DateTime queriedAt = DateTime.now();

  Identity(this.accountNumber, this.blockchain, this.name);
}
