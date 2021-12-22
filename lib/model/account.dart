import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  String accountNumber;
  String email;
  String alias;
  String fullName;
  String bio;
  String location;
  String website;
  String avatarURI;

  Account(
      {required this.accountNumber,
      required this.email,
      required this.alias,
      required this.fullName,
      required this.bio,
      required this.location,
      required this.website,
      required this.avatarURI});

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
}
