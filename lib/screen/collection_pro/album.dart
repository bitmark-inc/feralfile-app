import 'package:collection/collection.dart';
import 'package:nft_collection/database/dao/album_dao.dart';

extension MediumCategoryExt on MediumCategory {
  static String getName(String medium) {
    switch (medium) {
      case MediumCategory.image:
        return 'Still';
      case MediumCategory.video:
        return 'Video';
      case MediumCategory.model:
        return '3D';
      case MediumCategory.webView:
        return 'Interactive';
      default:
        return 'Other';
    }
  }

  static String icon(String medium) {
    switch (medium) {
      case MediumCategory.image:
        return 'assets/images/medium_image.svg';
      case MediumCategory.video:
        return 'assets/images/medium_video.svg';
      case MediumCategory.model:
        return 'assets/images/medium_3d.svg';
      case MediumCategory.webView:
        return 'assets/images/medium_software.svg';
      default:
        return 'assets/images/medium_other.svg';
    }
  }

  static List<String> getAllCategories() {
    return [
      MediumCategory.image,
      MediumCategory.video,
      MediumCategory.model,
      MediumCategory.webView,
    ];
  }

  static List<String> getAllMimeType() {
    return getAllCategories()
        .map((e) => MediumCategory.mineTypes(e))
        .flattened
        .toList();
  }
}
