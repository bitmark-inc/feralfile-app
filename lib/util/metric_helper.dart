enum MetricEventName {
  openApp,
  dailyView,
  playlistView,
  exhibitionView;

  String get name {
    switch (this) {
      case MetricEventName.openApp:
        return 'MOBILE_APP_OPEN';
      case MetricEventName.dailyView:
        return 'DAILY_VIEW';
      case MetricEventName.playlistView:
        return 'PLAYLIST_VIEW';
      case MetricEventName.exhibitionView:
        return 'EXHIBITION_VIEW';
    }
  }
}

enum MetricParameter {
  tokenId,
  section,
  exhibitionId;

  String get name {
    switch (this) {
      case MetricParameter.tokenId:
        return 'token_id';
      case MetricParameter.section:
        return 'section';
      case MetricParameter.exhibitionId:
        return 'exhibition_id';
    }
  }
}

const platform = 'Feral File App';
