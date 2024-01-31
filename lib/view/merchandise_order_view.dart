import 'package:autonomy_flutter/model/merchandise_order.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
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
            SelectableText(
              'order_'.tr(args: [order.id]),
              style: Theme.of(context).textTheme.moMASans700Black18,
            ),
            const SizedBox(height: 20),
            ...order.data.items.map((item) => MerchandiseOrderItemView(
                  name: '${item.variant.product.name}  ${item.variant.name}',
                  quantity: item.quantity,
                  note: '_per_item'.tr(args: [item.variant.price.toString()]),
                  total: item.variant.price * item.quantity,
                )),
            MerchandiseOrderItemView(
              name: 'shipping_fee'.tr(),
              total: order.data.shippingFee,
            ),
            MerchandiseOrderItemView(
              name: 'total'.tr(),
              total: order.data.totalCosts,
              isBold: true,
            ),
            addDivider(color: AppColor.primaryBlack),
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
      this.note,
      this.isBold = false});

  final int? quantity;
  final String name;
  final String? note;
  final double total;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addDivider(color: AppColor.primaryBlack),
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
                    style:
                        Theme.of(context).textTheme.ppMori400Black14.copyWith(
                              fontWeight: isBold ? FontWeight.bold : null,
                            ),
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
