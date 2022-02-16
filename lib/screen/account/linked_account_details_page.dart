import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/src/provider.dart';

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage> {
  @override
  void initState() {
    super.initState();

    context.read<FeralfileBloc>().add(GetFFAccountInfoEvent(widget.connection));
  }

  @override
  Widget build(BuildContext context) {
    final addressStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    final balanceStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.toUpperCase(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              child: BlocBuilder<FeralfileBloc, FeralFileState>(
                builder: (context, state) {
                  final wyreWallet =
                      state.connection?.ffConnection?.ffAccount.wyreWallet;

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Linked address",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            SvgPicture.asset("assets/images/iconBitmark.svg"),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                state.connection?.accountNumber ?? "",
                                style: addressStyle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Crypto",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'USD Coin (USDC)',
                              style: appTextTheme.headline4,
                            ),
                            if (wyreWallet == null) ...[
                              Text(
                                "-- USDC",
                                style: balanceStyle,
                              ),
                            ] else ...[
                              Text(
                                "${wyreWallet.availableBalances['USDC'] ?? 0} USDC",
                                style: balanceStyle,
                              ),
                            ]
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 40),
                        Text(
                          "Backup",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Text(
                            "The keys for this account are in FeralFile. You should manage your key backups there.",
                            style: appTextTheme.bodyText1),
                      ]);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
