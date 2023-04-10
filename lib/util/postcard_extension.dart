import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';

extension PostcardMetadataExtension on PostcardMetadata {
  String get title {
    return this.title;
  }

  String get description {
    return this.description;
  }

  String get image {
    return this.image;
  }

  String get url {
    return this.url;
  }

  List<String> get listOwner {
    return List.generate(12, (index) => lastOwner);
  }
}
