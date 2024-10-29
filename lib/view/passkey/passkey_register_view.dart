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

class PasskeyRegisterView extends StatefulWidget {
  const PasskeyRegisterView({super.key});

  @override
  State<PasskeyRegisterView> createState() => _PasskeyRegisterViewState();
}

class _PasskeyRegisterViewState extends State<PasskeyRegisterView> {
  final _passkeyService = injector.get<PasskeyService>();
  final _accountService = injector.get<AccountService>();

  bool _isError = false;
  bool _registering = false;
  bool _didSuccess = false;

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
        _didSuccess
            ? 'passkey_created'.tr()
            : _isError
                ? 'authentication_failed'.tr()
                : 'introducing_passkey'.tr(),
        style: Theme.of(context).textTheme.ppMori700Black16,
      );

  Widget _getDesc(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.ppMori400Black14;
    if (_didSuccess) {
      return Column(
        children: [
          Text(
            'passkey_created_desc'.tr(),
            style: style,
          ),
        ],
      );
    }
    if (_isError) {
      return Column(
        children: [
          Text(
            'passkey_error_desc'.tr(),
            style: style,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'introducing_passkey_desc_1'.tr(),
          style: style,
        ),
        const SizedBox(height: 10),
        Text(
          'introducing_passkey_desc_2'.tr(),
          style: style,
        ),
      ],
    );
  }

  Widget _getIcon() {
    if (_didSuccess) {
      return SvgPicture.asset(
        'assets/images/selected_round.svg',
      );
    }
    return SvgPicture.asset(
      'assets/images/passkey_icon.svg',
    );
  }

  Widget _getAction(BuildContext context) {
    if (_didSuccess) {
      return PrimaryButton(
        text: 'continue'.tr(),
        onTap: () {
          Navigator.of(context).pop(true);
        },
      );
    }
    return PrimaryAsyncButton(
      key: const Key('register_button'),
      onTap: _register,
      text: 'get_started'.tr(),
      processingText: _isError ? 'try_again'.tr() : 'creating_passkey'.tr(),
    );
  }

  Future<void> _register() async {
    if (_registering) {
      return;
    }
    setState(() {
      _registering = true;
      _isError = false;
    });
    try {
      await _passkeyService.registerInitiate();
      await _accountService.migrateAccount(() async {
        await _passkeyService.registerFinalize();
      });
      setState(() {
        _didSuccess = true;
      });
    } on Exception catch (e, stackTrace) {
      log.info('Failed to register passkey: $e');
      unawaited(Sentry.captureException(e, stackTrace: stackTrace));
      setState(() {
        _isError = true;
      });
    } finally {
      setState(() {
        _registering = false;
      });
    }
  }

  Widget _havingTrouble(BuildContext context) {
    if (_didSuccess || (!_isError && !_registering)) {
      return const SizedBox();
    }
    return const HavingTroubleView();
  }
}
