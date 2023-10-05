import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nft_collection/database/dao/album_dao.dart';

extension MediumCategoryExt on MediumCategory {
  static String getName(String medium) {
    switch (medium) {
      case MediumCategory.image:
        return 'still'.tr();
      case MediumCategory.video:
        return 'video'.tr();
      case MediumCategory.model:
        return '3d'.tr();
      case MediumCategory.webView:
        return 'interactive'.tr();
      default:
        return 'other'.tr();
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

  static List<String> getAllMediums() {
    return getAllCategories().map((e) => mediums(e)).flattened.toList();
  }

  static List<String> mediums(String category) {
    switch (category) {
      case MediumCategory.image:
        return [
          "image",
          "gif",
        ];
      case MediumCategory.video:
        return [
          "video",
        ];
      case MediumCategory.model:
        return [
          "model",
        ];
      case MediumCategory.webView:
        return [
          "software",
        ];
    }
    return [];
  }
}
