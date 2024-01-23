import 'package:autonomy_flutter/model/merchandise_order.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MerchandiseOrderView extends StatelessWidget {
  const MerchandiseOrderView({required this.order, super.key});

  final MerchandiseOrder order;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'order_'.tr(args: [order.id]),
              style: Theme.of(context).textTheme.moMASans700Black18,
            ),
            const SizedBox(height: 20),
            Text(
              'estimated_delivery_date'.tr(),
              style: Theme.of(context).textTheme.moMASans700Black14,
            ),
            const SizedBox(height: 20),
            ...order.data.variants.map((variant) => MerchandiseOrderItemView(
                  name: '${variant.item.product.name}  ${variant.item.name}',
                  quantity: variant.quantity,
                  note: '_per_item'.tr(args: [variant.item.price.toString()]),
                  total: variant.item.price * variant.quantity,
                )),
            MerchandiseOrderItemView(
              name: 'total'.tr(),
              total: order.data.totalCosts,
            ),
            addDivider()
          ],
        ),
      );
}

class MerchandiseOrderItemView extends StatelessWidget {
  const MerchandiseOrderItemView(
      {required this.name,
      required this.total,
      super.key,
      this.quantity,
      this.note});

  final int? quantity;
  final String name;
  final String? note;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addDivider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: quantity == null
                  ? const SizedBox()
                  : Text(
                      'x$quantity',
                      style: Theme.of(context).textTheme.moMASans400Black14,
                    ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.moMASans700Black14,
                  ),
                  if (note != null)
                    Text(
                      '(${note!})',
                      style: theme.textTheme.moMASans400Grey14
                          .copyWith(color: AppColor.auQuickSilver),
                    ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.ppMori700Black14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
