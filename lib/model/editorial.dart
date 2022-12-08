//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

part 'editorial.g.dart';

@JsonSerializable()
class Editorial {
  List<EditorialPost> editorial;

  Editorial({
    required this.editorial,
  });

  factory Editorial.fromJson(Map<String, dynamic> json) => _$EditorialFromJson(json);

  Map<String, dynamic> toJson() => _$EditorialToJson(this);
}

@JsonSerializable()
class EditorialPost {
  String type;
  Publisher publisher;
  Map<String, dynamic> content;
  Reference? reference;
  String? tag;

  EditorialPost({
    required this.type,
    required this.publisher,
    required this.content,
    this.reference,
    this.tag,
  });

  factory EditorialPost.fromJson(Map<String, dynamic> json) => _$EditorialPostFromJson(json);

  Map<String, dynamic> toJson() => _$EditorialPostToJson(this);
}

@JsonSerializable()
class Publisher {
  String name;
  String icon;
  String? intro;

  Publisher({required this.name, required this.icon, this.intro});

  factory Publisher.fromJson(Map<String, dynamic> json) => _$PublisherFromJson(json);

  Map<String, dynamic> toJson() => _$PublisherToJson(this);
}

@JsonSerializable()
class Reference {
  String location;
  String website;
  List<Social> socials;

  Reference(
      {required this.location, required this.website, required this.socials});

  factory Reference.fromJson(Map<String, dynamic> json) => _$ReferenceFromJson(json);

  Map<String, dynamic> toJson() => _$ReferenceToJson(this);
}

@JsonSerializable()
class Social {
  String name;
  String url;

  Social({required this.name, required this.url});

  factory Social.fromJson(Map<String, dynamic> json) => _$SocialFromJson(json);

  Map<String, dynamic> toJson() => _$SocialToJson(this);
}
