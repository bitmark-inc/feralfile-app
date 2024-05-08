import 'package:autonomy_flutter/model/add_ethereum_chain.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class AddEthereumChainPage extends StatefulWidget {
  const AddEthereumChainPage({required this.payload, super.key});

  final AddEthereumChainPagePayload payload;

  @override
  State<AddEthereumChainPage> createState() => _AddEthereumChainPageState();
}

class _AddEthereumChainPageState extends State<AddEthereumChainPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = widget.payload.parameter;
    final textStyles = theme.textTheme.ppMori400Black14;
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: 'add_ethereum_chain_request'.tr(),
      ),
      body: Container(
        margin: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    Text(
                        'Confirm to allow connect to this chain.'
                        ' This action solely will not sign any '
                        'message or transaction',
                        style: textStyles),
                    const SizedBox(height: 10),
                    if (params.iconUrls != null && params.iconUrls!.isNotEmpty)
                      Image.network(
                        params.iconUrls!.first,
                        width: 64,
                        height: 64,
                      ),
                    const SizedBox(height: 30),
                    Text('Blockchain: ${params.chainName ?? 'Unknown'}',
                        style: textStyles),
                    const SizedBox(height: 10),
                    Text('Chain: ${params.chainNet}', style: textStyles),
                  ],
                ),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                onTap: () {
                  Navigator.of(context).pop(true);
                },
                text: 'confirm'.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEthereumChainPagePayload {
  final AddEthereumChainParameter parameter;

  const AddEthereumChainPagePayload({required this.parameter});
}
