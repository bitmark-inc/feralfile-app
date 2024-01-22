import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/merchandise_order.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/merchandise_service.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/merchandise_order_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
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
    orderIds.add('b6714e85-d12b-4b65-adb6-90b63f9caf1f');
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
          titleStyle: Theme.of(context).textTheme.ppMori700Black14,
          onClose: () {
            Navigator.pop(context);
          },
          title: 'purchase_history',
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              ..._orders.map((e) => MerchandiseOrderView(order: e))
            ],
          ),
        ),
      );
}
