enum MetricEventName {
  openApp,
  dailyView,
  playlistView,
  exhibitionView,
  dailyLiked,
  ;

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
      case MetricEventName.dailyLiked:
        return 'DAILY_LIKED';
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
        return 'tokenID';
      case MetricParameter.section:
        return 'section';
      case MetricParameter.exhibitionId:
        return 'exhibitionID';
    }
  }
}

const platform = 'Feral File App';
