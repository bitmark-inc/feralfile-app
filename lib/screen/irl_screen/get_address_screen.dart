import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IRLGetAddressPayLoad {
  final String? blockchain;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? metadata;

  IRLGetAddressPayLoad({
    this.blockchain,
    this.params,
    this.metadata,
  });
}

class IRLGetAddressPage extends StatefulWidget {
  final IRLGetAddressPayLoad? payload;

  const IRLGetAddressPage({
    Key? key,
    this.payload,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IRLGetAddressPageState();
  }
}

class _IRLGetAddressPageState extends State<IRLGetAddressPage> with RouteAware {
  String? _selectedAddress;

  @override
  void initState() {
    _callAccountEvent();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _callAccountEvent();
    super.didPopNext();
  }

  void _callAccountEvent() {
    if (widget.payload?.blockchain?.toLowerCase() == "tezos") {
      context.read<AccountsBloc>().add(GetCategorizedAccountsEvent(
          getEth: false, includeLinkedAccount: false));
    } else {
      context.read<AccountsBloc>().add(GetCategorizedAccountsEvent(
          getTezos: false, includeLinkedAccount: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: "address_request".tr(),
      ),
      body: Container(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                "address_request".tr(),
                style: theme.textTheme.ppMori700Black24,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                widget.payload?.metadata?['description'] ?? '',
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: _buildAddressList(context),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                text: "h_confirm".tr(),
                onTap: _selectedAddress == null
                    ? null
                    : () => Navigator.pop(context, _selectedAddress),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final accounts = state.accounts ?? [];
      return ListAccountConnect(
        accounts: accounts,
        onSelectEth: (value) {
          setState(() {
            if (widget.payload?.blockchain?.toLowerCase() != "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
        onSelectTez: (value) {
          setState(() {
            if (widget.payload?.blockchain?.toLowerCase() == "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
      );
    });
  }
}
