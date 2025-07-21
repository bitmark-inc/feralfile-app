import 'package:flutter/material.dart';

class IconSwitcherItem {
  IconSwitcherItem({
    required this.icon,
    required this.iconOnSelected,
    this.onTap,
  });

  final Widget icon;
  final Widget? iconOnSelected;
  final Function? onTap;
}

class IconSwitcher extends StatefulWidget {
  const IconSwitcher({required this.items, super.key, this.initialIndex = 0});

  final List<IconSwitcherItem> items;
  final int initialIndex;

  @override
  IconSwitcherState createState() => IconSwitcherState();
}

class IconSwitcherState extends State<IconSwitcher> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(IconSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        selectedIndex = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const itemMargin = 4.0;
    final itemCount = widget.items.length;
    const itemWidth = 56.0;
    const itemHeight = 30.0;
    const borderWidth = 2.0;
    final width =
        itemWidth * itemCount + itemMargin * (itemCount - 1) + borderWidth * 2;
    const height = itemHeight;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: selectedIndex * itemWidth + selectedIndex * itemMargin,
          top: 0,
          bottom: 0,
          width: itemWidth + borderWidth * 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: borderWidth),
            ),
          ),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: borderWidth,
            ),
          ),
          child: Row(
            children: List.generate(itemCount, (index) {
              final item = widget.items[index];
              return Padding(
                padding: (index < itemCount - 1)
                    ? const EdgeInsets.only(right: itemMargin)
                    : EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    item.onTap?.call();
                  },
                  child: Container(
                    width: itemWidth,
                    height: itemHeight,
                    alignment: Alignment.center,
                    child: selectedIndex == index
                        ? item.iconOnSelected ?? item.icon
                        : item.icon,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
