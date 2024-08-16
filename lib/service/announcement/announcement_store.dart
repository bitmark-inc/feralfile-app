import 'package:autonomy_flutter/model/announcement/announcement_local.dart';
import 'package:autonomy_flutter/service/hive_store_service.dart';

class AnnouncementStore extends HiveStoreObjectServiceImpl<AnnouncementLocal> {
  static const String _key = 'local.announcement';

  @override
  Future<void> init(String key) async {
    await super.init(_key);
  }
}