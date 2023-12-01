import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Prompt {
  final String id;
  final String? color;
  final String? title;
  final String description;
  final String? cid;

  //constructor
  Prompt({
    required this.id,
    required this.description,
    this.color,
    this.title,
    this.cid,
  });

  // from json factory
  factory Prompt.fromJson(Map<String, dynamic> map) => Prompt(
        id: (map['id'] as String?) ?? const Uuid().v4(),
        color: map['color'] as String?,
        title: map['title'] as String?,
        description: map['description'] as String,
        cid: map['cid'] as String?,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color,
        'title': title,
        'description': description,
        'cid': cid,
      };

  Color? get colorAsColor {
    if (color == null) {
      return null;
    }

    /// TODO: implement colorAsColor
    return MomaPallet.pink;
  }
}
