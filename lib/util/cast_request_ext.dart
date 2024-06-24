import 'package:feralfile_app_tv_proto/models/model.dart';

extension CastExhibitionRequestExt on CastExhibitionRequest {
  String get displayKey => exhibitionId ?? '';
}
