import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:easy_localization/easy_localization.dart';

extension FeralfileErrorExt on FeralfileError {
  String get dialogTitle {
    switch (code) {
      case 5006:
        return "Too soon";
      case 3007:
        return "Too late";
      case 3009:
        return "Out of token";
      case 3010:
        return "Just once";
      case 3013:
      case 3014:
        return "One more time";
      default:
        return "error".tr();
    }
  }

  String get dialogMessage {
    switch (code) {
      case 5006:
        return "It is not yet possible to redeem this gift edition.";
      case 3007:
        return "It is no longer possible to redeem this gift edition.";
      case 3009:
        return "Sorry, the tokens have been delivered to all fastest users.";
      case 3010:
        return "You have already accepted your gift edition.";
      case 3013:
      case 3014:
        return "The validity of the QR code has expired. Please scan the QR code again.";
      default:
        return message;
    }
  }

  String getDialogTitle() {
    return dialogTitle;
  }

  String getDialogMessage({FFSeries? series}) {
    if (code == 3009 && (series?.maxEdition ?? 0) < 0) {
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
        url = "https://goerli.etherscan.io/address/$address}";
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
    return (fullName?.isNotEmpty == true) ? fullName! : alias;
  }
}

extension AirdropInfoExt on AirdropInfo {
  String getTokenIndexerId(String tokenId) {
    final prefix = blockchain.toLowerCase() == "tezos" ? "tez" : "eth";
    return "$prefix-$contractAddress-$tokenId";
  }
}
