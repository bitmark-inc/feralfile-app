import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/merchandise_order.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/merchandise_service.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/merchandise_order_view.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MerchandiseOrderPage extends StatefulWidget {
  const MerchandiseOrderPage({super.key});

  @override
  State<MerchandiseOrderPage> createState() => _MerchandiseOrderPageState();
}

class _MerchandiseOrderPageState extends State<MerchandiseOrderPage> {
  final _merchandiseService = injector<MerchandiseService>();
  final List<MerchandiseOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    unawaited(_fetchOrders());
  }

  Future<void> _fetchOrders() async {
    final orderIds = injector<ConfigurationService>().getMerchandiseOrderIds();
    for (final id in orderIds) {
      final order = await _merchandiseService.getOrder(id);
      setState(() {
        _orders.add(order);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getCloseAppBar(
          context,
          titleStyle: Theme.of(context).textTheme.moMASans700Black18,
          withBottomDivider: false,
          onClose: () {
            Navigator.pop(context);
          },
          title: 'purchase_history'.tr(),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                ..._orders.map((e) => MerchandiseOrderView(order: e))
              ],
            ),
          ),
        ),
      );
}
