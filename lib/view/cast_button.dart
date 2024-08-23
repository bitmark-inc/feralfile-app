import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/stream_device_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FFCastButton extends StatefulWidget {
  final Function(CanvasDevice device)? onDeviceSelected;
  final String displayKey;
  final String? text;
  final String? type;
  final bool shouldCheckSubscription;

  const FFCastButton({
    required this.displayKey,
    this.type = '',
    super.key,
    this.onDeviceSelected,
    this.text,
    this.shouldCheckSubscription = true,
  });

  @override
  State<FFCastButton> createState() => _FFCastButtonState();
}

class _FFCastButtonState extends State<FFCastButton> {
  late CanvasDeviceBloc _canvasDeviceBloc;
  final keyboardManagerKey = GlobalKey<KeyboardManagerWidgetState>();
  final _upgradesBloc = UpgradesBloc(injector(), injector());

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
    _upgradesBloc.add(UpgradeQueryInfoEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: _canvasDeviceBloc,
      builder: (context, state) {
        final castingDevice =
            state.lastSelectedActiveDeviceForKey(widget.displayKey);
        final isCasting = castingDevice != null;
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, subscriptionState) {
          final isSubscribed = subscriptionState.isSubscribed;
          return IconButton(
            onPressed: () async {
              if (!widget.shouldCheckSubscription || isSubscribed) {
                await _showStreamAction(context, widget.displayKey);
              } else {
                await _showUpgradeDialog(context);
              }
            },
            icon: Semantics(
              label: 'cast_icon',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: AppColor.feralFileLightBlue,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9)
                      .copyWith(left: 16, right: isCasting ? 9 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.text != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            widget.text!,
                            style: theme.textTheme.ppMori400Black14.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      SvgPicture.asset(
                        'assets/images/cast_icon.svg',
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      if (isCasting) ...[
                        const SizedBox(
                          width: 3,
                          height: 20,
                        ),
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: const BoxDecoration(
                            color: AppColor.primaryBlack,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _showStreamAction(
      BuildContext context, String displayKey) async {
    keyboardManagerKey.currentState?.hideKeyboard();
    await UIHelper.showFlexibleDialog(
      context,
      BlocProvider.value(
        value: _canvasDeviceBloc,
        child: StreamDeviceView(
          displayKey: displayKey,
          onDeviceSelected: (canvasDevice) {
            widget.onDeviceSelected?.call(canvasDevice);
            Navigator.pop(context);
          },
        ),
      ),
      isDismissible: true,
    );
  }

  Future<void> _showUpgradeDialog(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      'see_more_art'.tr(),
      BlocProvider.value(
        value: _upgradesBloc,
        child: BlocConsumer<UpgradesBloc, UpgradeState>(
            bloc: _upgradesBloc,
            listener: (context, upgradeState) {
              final status =
                  upgradeState.subscriptionDetails.firstOrNull?.status;
              log.info('Cast button: upgradeState: $status');
              if (status == IAPProductStatus.completed) {
                Navigator.pop(context);
              }
            },
            builder: (context, upgradeState) {
              final subscriptionDetail =
                  upgradeState.activeSubscriptionDetails.firstOrNull;
              final price = subscriptionDetail?.price ?? r'$200/year';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'you_need_to_subscribe'.tr(),
                    style: Theme.of(context).textTheme.ppMori400White14,
                  ),
                  const SizedBox(height: 20),
                  MembershipCard(
                    type: MembershipCardType.premium,
                    price: price,
                    isProcessing: upgradeState.isProcessing,
                    isEnable: subscriptionDetail != null &&
                        !upgradeState.isProcessing,
                    onTap: (_) {
                      _onPressSubscribe(
                          subscriptionDetails: subscriptionDetail!);
                    },
                    buttonText: 'upgrade'.tr(),
                  ),
                ],
              );
            }),
      ),
      isDismissible: true,
    );
  }

  void _onPressSubscribe({required SubscriptionDetails subscriptionDetails}) {
    final ids = [subscriptionDetails.productDetails.id];
    log.info('Cast button: upgrade purchase: ${ids.first}');
    _upgradesBloc.add(UpgradePurchaseEvent(ids));
  }
}
