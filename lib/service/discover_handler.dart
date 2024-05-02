import 'package:bonsoir/bonsoir.dart';

abstract class DiscoverHandler {
  void handleServiceResolved(BonsoirService service);

  void handleServiceLost(BonsoirService service);
}
