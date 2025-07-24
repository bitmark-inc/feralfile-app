import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart'; // Added for AppColor
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

ValueNotifier<bool> isNowDisplayingExpanded = ValueNotifier(false);

class ExpandableNowDisplayingView extends StatefulWidget {
  final Widget Function(BuildContext) thumbnailBuilder;
  final Widget Function(BuildContext) titleBuilder;
  final BaseDevice? device;
  final List<Widget> customAction;
  final List<OptionItem> options;

  const ExpandableNowDisplayingView({
    super.key,
    required this.thumbnailBuilder,
    required this.titleBuilder,
    this.device,
    this.customAction = const [],
    required this.options,
  });

  @override
  State<ExpandableNowDisplayingView> createState() =>
      _ExpandableNowDisplayingViewState();
}

class _ExpandableNowDisplayingViewState
    extends State<ExpandableNowDisplayingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isNowDisplayingExpanded,
        builder: (context, value, child) {
          // Start animation when expanded state changes
          if (value) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NowDisplayingView(
                  thumbnailBuilder: widget.thumbnailBuilder,
                  titleBuilder: widget.titleBuilder,
                  device: widget.device,
                  customAction: widget.customAction,
                  onMoreTap: () {
                    setState(() {
                      isNowDisplayingExpanded.value = !value;
                    });
                  },
                  moreIcon: SvgPicture.asset(
                    value
                        ? 'assets/images/close.svg'
                        : 'assets/images/icon_drawer.svg',
                    width: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColor.primaryBlack,
                      BlendMode.srcIn,
                    ),
                  ), // Pass the dynamic icon here
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      height: _heightAnimation.value *
                          (widget.options.length *
                              60.0), // Approximate height for each option
                      child: SingleChildScrollView(
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: value
                              ? ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final option = widget.options[index];
                                    if (option.builder != null) {
                                      return option.builder!
                                          .call(context, option);
                                    }
                                    return DrawerItem(
                                      item: option,
                                      color: AppColor.primaryBlack,
                                    );
                                  },
                                  itemCount: widget.options.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColor.primaryBlack,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
