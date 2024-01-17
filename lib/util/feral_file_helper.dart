import 'package:autonomy_flutter/common/environment.dart';

class FeralFileHelper {
  static final String _baseUrl = Environment.feralFileAPIURL;

  static String getArtistUrl(String alias) => '$_baseUrl/artists/$alias';

  static String getCuratorUrl(String alias) => '$_baseUrl/curators/$alias';
}
