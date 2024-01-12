import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class ViewExistingAddress extends StatefulWidget {
  static const String tag = 'view_existing_address';
  final ViewExistingAddressPayload payload;

  const ViewExistingAddress({required this.payload, super.key});

  @override
  State<ViewExistingAddress> createState() => _ViewExistingAddressState();
}

class _ViewExistingAddressState extends State<ViewExistingAddress> {
  final _controller = TextEditingController();
  bool _isError = false;
  String _address = '';
  bool _isValid = false;
  final _checkDomainLock = Lock();
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context,
          title: 'view_existing_address'.tr(),
          onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    Text('enter_a_wallet_address'.tr(),
                        style: theme.textTheme.ppMori400Black14),
                    const SizedBox(height: 10),
                    AuTextField(
                      title: '',
                      placeholder: 'enter_address'.tr(),
                      controller: _controller,
                      isError: _isError,
                      suffix: IconButton(
                        icon: Icon(_controller.text.isEmpty
                            ? AuIcon.scan
                            : AuIcon.close),
                        onPressed: () async {
                          if (_controller.text.isNotEmpty) {
                            _controller.clear();
                            setState(() {
                              _isValid = false;
                              _address = '';
                            });
                            return;
                          }
                          dynamic address = await Navigator.of(context)
                              .pushNamed(ScanQRPage.tag,
                                  arguments: ScannerItem.ETH_ADDRESS);
                          if (address != null && address is String) {
                            address = address.replacePrefix('ethereum:', '');
                            _controller.text = address;
                            await _onTextChanged(address);
                          }
                        },
                      ),
                      onChanged: _onTextChanged,
                    ),
                  ],
                ),
              ),
            ),
            PrimaryAsyncButton(
              enabled: _address.isNotEmpty && _isValid,
              text: 'continue'.tr(),
              onTap: () async {
                final address = _address;
                final cryptoType = CryptoType.fromAddress(address);
                switch (cryptoType) {
                  case CryptoType.ETH:
                  case CryptoType.XTZ:
                    try {
                      final connection = await injector<AccountService>()
                          .linkManuallyAddress(address, cryptoType,
                              name: _address != _controller.text.trim()
                                  ? _controller.text.trim()
                                  : null);
                      if (!mounted) {
                        return;
                      }
                      unawaited(Navigator.of(context).pushNamed(
                          AppRouter.nameLinkedAccountPage,
                          arguments: connection));
                    } on LinkAddressException catch (e) {
                      setState(() {
                        _isError = true;
                      });
                      await UIHelper.showInfoDialog(context, e.message, '',
                          isDismissible: true,
                          closeButton: 'close'.tr(), onClose: () {
                        Navigator.of(context).popUntil((route) =>
                            route.settings.name ==
                                AppRouter.homePageNoTransition ||
                            route.settings.name == AppRouter.homePage ||
                            route.settings.name == AppRouter.walletPage);
                      });
                    } catch (_) {}
                    break;
                  default:
                    setState(() {
                      _isError = true;
                    });
                }
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed(ImportSeedsPage.tag);
              },
              child: Text('or_import_address'.tr(),
                  style: theme.textTheme.ppMori400Black14
                      .copyWith(decoration: TextDecoration.underline)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _onTextChanged(value) async {
    _timer?.cancel();
    final text = value.trim();
    if (text.isEmpty) {
      setState(() {
        _isValid = false;
      });
      return;
    }
    setState(() {
      _isError = false;
    });
    final type = CryptoType.fromAddress(text);
    if (type == CryptoType.ETH || type == CryptoType.XTZ) {
      _setValid(text);
    } else {
      _timer = Timer(const Duration(milliseconds: 500), () async {
        await _checkDomain(text);
      });
    }
  }

  Future<void> _checkDomain(String text) async {
    await _checkDomainLock.synchronized(() async {
      if (text.isNotEmpty) {
        try {
          final address = await DomainService.getAddress(text);
          if (address != null) {
            _setValid(address);
          } else {
            setState(() {
              _isValid = false;
            });
          }
        } catch (_) {}
      }
    });
  }

  void _setValid(String value) {
    setState(() {
      _isValid = true;
      _address = value;
    });
  }
}

// payload class
class ViewExistingAddressPayload {
  final bool isOnboarding;

  ViewExistingAddressPayload(this.isOnboarding);
}
