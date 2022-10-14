import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:easy_localization/easy_localization.dart';

extension FeralfileErrorExt on FeralfileError {
  String get dialogTitle {
    switch (code) {
      case 5006:
        return "Too soon";
      case 5011:
        return "Too late";
      case 5013:
        return "Out of token";
      case 5014:
        return "Just once";
      default:
        return "error".tr();
    }
  }

  String get dialogMessage {
    switch (code) {
      case 5006:
        return "It is not yet possible to redeem this gift edition.";
      case 5011:
        return "It is no longer possible to redeem this gift edition.";
      case 5013:
        return "Sorry, the tokens have been delivered to all fastest users.";
      case 5014:
        return "You have already accepted your gift edition.";
      default:
        return message;
    }
  }

  String getDialogTitle({required Exhibition exhibition}) {
    return dialogTitle;
  }

  String getDialogMessage({required Exhibition exhibition}) {
    if (code == 5013 && exhibition.maxEdition < 0) {
      return "We are running out of tokens. Come back later.";
    } else {
      return dialogMessage;
    }
  }
}

extension FFContractExt on FFContract {
  String? getBlockChainUrl() {
    final network = Environment.appTestnetConfig ? "TESTNET" : "MAINNET";
    String? url;
    switch ("${network}_$blockchainType") {
      case "MAINNET_ethereum":
        url = "https://etherscan.io/address/$address";
        break;

      case "TESTNET_ethereum":
        url = "https://rinkeby.etherscan.io/address/$address}";
        break;

      case "MAINNET_tezos":
      case "TESTNET_tezos":
        url = "https://tzkt.io/$address";
        break;
    }
    return url;
  }
}

extension FFArtistExt on FFArtist {
  String getDisplayName() {
    return fullName.isNotEmpty ? fullName : alias;
  }
}

extension AirdropInfoExt on AirdropInfo {
  String getTokenIndexerId(String tokenId) {
    final prefix = blockchain.toLowerCase() == "tezos" ? "tez" : "eth";
    return "$prefix-$contractAddress-$tokenId";
  }
}
