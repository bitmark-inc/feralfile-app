import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/passkey/having_trouble_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PasskeyLoginView extends StatefulWidget {
  const PasskeyLoginView({super.key});

  @override
  State<PasskeyLoginView> createState() => _PasskeyLoginViewState();
}

class _PasskeyLoginViewState extends State<PasskeyLoginView> {
  final _passkeyService = injector.get<PasskeyService>();
  final _accountService = injector.get<AccountService>();

  bool _isError = false;
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getTitle(context),
              const SizedBox(height: 20),
              _getDesc(context),
            ],
          ),
          const SizedBox(height: 20),
          _getIcon(),
          const SizedBox(height: 20),
          _getAction(context),
          const SizedBox(height: 20),
          _havingTrouble(context)
        ],
      );

  Widget _getTitle(BuildContext context) => Text(
        _isError ? 'authentication_failed'.tr() : 'login_title'.tr(),
        style: Theme.of(context).textTheme.ppMori700Black16,
      );

  Widget _getDesc(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.ppMori400Black14;
    return Text(
      _isError ? 'passkey_error_desc'.tr() : 'login_desc'.tr(),
      style: style,
    );
  }

  Widget _getIcon() => SvgPicture.asset(
        'assets/images/passkey_icon.svg',
      );

  Widget _getAction(BuildContext context) => PrimaryAsyncButton(
        key: const Key('login_button'),
        onTap: _login,
        text: _isError ? 'try_again'.tr() : 'login_button'.tr(),
      );

  Future<void> _login() async {
    if (_isLogging) {
      return;
    }
    setState(() {
      _isLogging = true;
      _isError = false;
    });
    try {
      final localResponse = await _passkeyService.logInInitiate();
      await _accountService.migrateAccount(() async {
        await _passkeyService.logInFinalize(localResponse);
      });
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e, stackTrace) {
      log.info('Failed to login with passkey: $e');
      unawaited(Sentry.captureException(e, stackTrace: stackTrace));
      setState(() {
        _isError = true;
      });
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  Widget _havingTrouble(BuildContext context) {
    if (!_isError && !_isLogging) {
      return const SizedBox();
    }
    return const HavingTroubleView();
  }
}
