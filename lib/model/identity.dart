class BlockchainIdentity {
  String accountNumber;
  String blockchain;
  String name;

  BlockchainIdentity(this.accountNumber, this.blockchain, this.name);

  BlockchainIdentity.fromJson(Map<String, dynamic> json)
      : accountNumber = json['accountNumber'],
        blockchain = json['blockchain'],
        name = json['name'];
}
