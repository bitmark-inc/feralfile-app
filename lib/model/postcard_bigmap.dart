

class PostcardValue {
  String counter;
  String postman;
  bool stamped;

  PostcardValue(
      {required this.counter, required this.postman, required this.stamped});
  // from json factory
  factory PostcardValue.fromJson(Map<String, dynamic> map) {
    return PostcardValue(
      counter: map['counter'] as String,
      postman: map['postman'] as String,
      stamped: map['stamped'] as bool,
    );
  }
  // to json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'counter': counter,
      'postman': postman,
      'stamped': stamped,
    };
  }

}
