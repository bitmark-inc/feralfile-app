import 'package:walletconnect_flutter_v2/apis/sign_api/models/proposal_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';

extension Wc2Extension on String {
  // https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
  String get caip2Namespace {
    return split(":")[0];
  }
}

extension NameSpaces on RequiredNamespace {
  Namespace toNameSpace(List<String> accounts) {
    if (chains == null || chains!.isEmpty || accounts.isEmpty) {
      return Namespace(
        methods: methods,
        events: events,
        accounts: chains ?? [],
      );
    } else if (chains!.length == accounts.length) {
      List<String> chainsAccount =[];
      for (int i = 0; i < chains!.length; i++) {
        chainsAccount.add("${chains![i]}:${accounts[i]}");
      }
      return Namespace(
        methods: methods,
        events: events,
        accounts: chainsAccount,
      );
    } else {
      return Namespace(
          methods: methods,
          events: events,
          accounts: chains!.map((e) => "$e:${accounts[0]}").toList());
    }
  }
}
