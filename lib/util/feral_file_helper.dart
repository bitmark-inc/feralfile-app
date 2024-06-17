import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';

class FeralFileHelper {
  static final String _baseUrl = Environment.feralFileAPIURL;

  static String getArtistUrl(String alias) => '$_baseUrl/artists/$alias';

  static String getCuratorUrl(String alias) => '$_baseUrl/curators/$alias';

  static String getExhibitionNoteUrl(String exhibitionSlug) =>
      '$_baseUrl/exhibitions/$exhibitionSlug/overview#note';

  static String getPostUrl(Post post, String exhibitionID) =>
      '$_baseUrl/journal/${post.type}/${post.slug}/?exhibitionID=$exhibitionID';
}
