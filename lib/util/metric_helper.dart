enum MetricEventName {
  openApp;

  String get name {
    switch (this) {
      case MetricEventName.openApp:
        return 'MOBILE_APP_OPEN';
    }
  }
}

const platform = 'Feral File App';
