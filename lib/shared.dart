import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/route_ext.dart';

MemoryValues memoryValues = MemoryValues();

class MemoryValues {
  String? scopedPersona;
  String? viewingSupportThreadIssueID;
  DateTime? inForegroundAt;
  String? currentGroupChatId;
  bool isForeground = true;

  MemoryValues({
    this.scopedPersona,
    this.viewingSupportThreadIssueID,
    this.inForegroundAt,
  });

  MemoryValues copyWith({
    String? scopedPersona,
  }) =>
      MemoryValues(
        scopedPersona: scopedPersona ?? this.scopedPersona,
      );
}

enum HomeNavigatorTab {
  daily,
  explore,
  menu;

  String get screenName => getPageName(routeName);

  String get routeName {
    switch (this) {
      case HomeNavigatorTab.daily:
        return AppRouter.dailyWorkPage;
      case HomeNavigatorTab.explore:
        return AppRouter.explorePage;
      case HomeNavigatorTab.menu:
        return 'Menu';
    }
  }
}
