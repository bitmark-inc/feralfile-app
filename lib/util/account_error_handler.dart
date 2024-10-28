import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:passkeys/exceptions.dart';

class SignInException {
  final Exception exception;
  final SignType type;

  SignInException(this.exception, this.type);
}

enum SignType {
  register,
  login,
}

class AccountErrorHandler {
  static Future<dynamic> showDialog(BuildContext context,
      SignInException signException, StackTrace stackTrace) async {
    String? title;
    String? message;
    switch (signException.type) {
      case SignType.register:
        title = 'register_error_title'.tr();
        message = 'register_error_message'.tr();
      case SignType.login:
        title = 'login_error_title'.tr();
        message = 'login_error_message'.tr();
    }
    switch (signException.exception.runtimeType) {
      case PasskeyAuthCancelledException:
        message = 'auth_cancelled_message'.tr();
      case MissingGoogleSignInException:
      case SyncAccountNotAvailableException:
      case ExcludeCredentialsCanNotBeRegisteredException:
        message = 'sign_google_account_message'.tr();
      case NoCredentialsAvailableException:
        message = 'no_credentials_available_message'.tr();
    }
    return await showErrorDialog(context, title, message, 'close'.tr());
  }
}
