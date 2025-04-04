import 'package:objectbox/objectbox.dart';

@Entity()
class IndexerIdentity {
  IndexerIdentity(this.accountNumber, this.blockchain, this.name);
  @Id()
  int id = 0;

  @Unique()
  String accountNumber;
  String blockchain;
  String name;

  @Property(type: PropertyType.date)
  DateTime queriedAt = DateTime.now();
}
