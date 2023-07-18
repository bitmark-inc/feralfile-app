import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ViewExistingAddress extends StatefulWidget {
  static const String tag = 'view_existing_address';
  final ViewExistingAddressPayload payload;

  const ViewExistingAddress({Key? key, required this.payload})
      : super(key: key);

  @override
  State<ViewExistingAddress> createState() => _ViewExistingAddressState();
}

class _ViewExistingAddressState extends State<ViewExistingAddress> {
  final _controller = TextEditingController();
  bool _isError = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "view_existing_address".tr(),
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
                    Text("name_address".tr(),
                        style: theme.textTheme.ppMori400Black14),
                    const SizedBox(height: 10),
                    AuTextField(
                      title: "",
                      placeholder: "enter_address_alias".tr(),
                      controller: _controller,
                      isError: _isError,
                      suffix: IconButton(
                        icon: Icon(_controller.text.isEmpty
                            ? AuIcon.scan
                            : AuIcon.close),
                        onPressed: () async {
                          if (_controller.text.isNotEmpty) {
                            _controller.clear();
                            setState(() {});
                            return;
                          }
                          dynamic address = await Navigator.of(context)
                              .pushNamed(ScanQRPage.tag,
                                  arguments: ScannerItem.ETH_ADDRESS);
                          if (address != null && address is String) {
                            address = address.replacePrefix("ethereum:", "");
                            _controller.text = address;
                            setState(() {});
                          }
                        },
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isError = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              enabled: _controller.text.trim().isNotEmpty,
              text: "continue".tr(),
              isProcessing: _isProcessing,
              onTap: () async {
                setState(() {
                  _isProcessing = true;
                });
                final address = _controller.text.trim();
                final cryptoType = CryptoType.fromAddress(address);
                switch (cryptoType) {
                  case CryptoType.ETH:
                  case CryptoType.XTZ:
                    final connection = await injector<AccountService>()
                        .linkManuallyAddress(
                            _controller.text.trim(), cryptoType);
                    if (!mounted) return;
                    Navigator.of(context).pushNamed(
                        AppRouter.nameLinkedAccountPage,
                        arguments: connection);
                    break;
                  default:
                    setState(() {
                      _isError = true;
                    });
                }
                setState(() {
                  _isProcessing = false;
                });
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ImportSeedsPage.tag);
              },
              child: Text("or_import_address".tr(),
                  style: theme.textTheme.ppMori400Black14
                      .copyWith(decoration: TextDecoration.underline)),
            )
          ],
        ),
      ),
    );
  }
}

// payload class
class ViewExistingAddressPayload {
  final bool isOnboarding;

  ViewExistingAddressPayload(this.isOnboarding);
}
