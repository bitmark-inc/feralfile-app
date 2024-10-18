import 'package:autonomy_flutter/screen/app_router.dart';

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
  collection,
  menu;

  String get routeName {
    switch (this) {
      case HomeNavigatorTab.daily:
        return AppRouter.dailyWorkPage;
      case HomeNavigatorTab.explore:
        return AppRouter.explorePage;
      case HomeNavigatorTab.collection:
        return AppRouter.organizePage;
      case HomeNavigatorTab.menu:
        return 'Menu';
    }
  }
}
