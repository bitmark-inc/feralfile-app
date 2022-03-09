import 'package:intl/intl.dart';

final DateFormat _localtimeFormatter = DateFormat('yyyy-MM-dd\nhh:mm:ss');

String localTimeString(DateTime date) {
  return _localtimeFormatter.format(date.toLocal());
}

String localTimeStringFromISO8601(String str) {
  final date = DateTime.parse(str);
  return localTimeString(date);
}
