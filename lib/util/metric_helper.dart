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

const platform = 'Feral File App';
