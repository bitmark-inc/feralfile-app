class Message {
  String id;
  int timestamp;
  String sender;
  String message;

  Message({
    required this.id,
    required this.timestamp,
    required this.sender,
    required this.message,
  });

  // from json method
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      sender: json['sender'] as String,
      message: json['message'] as String,
    );
  }

  // to json method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'sender': sender,
      'message': message,
    };
  }
}

class WebsocketMessage {
  String command;
  String id;
  dynamic payload;

  WebsocketMessage({
    required this.command,
    required this.id,
    required this.payload,
  });

  factory WebsocketMessage.fromJson(Map<String, dynamic> json) {
    return WebsocketMessage(
      command: json['command'] as String,
      id: json['id'] as String,
      payload: json['payload'],
    );
  }
}
