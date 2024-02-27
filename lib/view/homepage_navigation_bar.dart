import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FFNavigationBarItem {
  final Widget icon;
  final Widget? unselectedIcon;
  final String label;
  final Color? selectedColor;
  final Color? unselectedColor;

  const FFNavigationBarItem({
    required this.icon,
    required this.label,
    this.unselectedIcon,
    this.selectedColor,
    this.unselectedColor,
  });
}

class FFNavigationBar extends StatefulWidget {
  final List<FFNavigationBarItem> items;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final Color backgroundColor;
  final void Function(int selectedIndex) onSelectTab;
  final int currentIndex;

  const FFNavigationBar(
      {required this.items,
      required this.onSelectTab,
      required this.selectedItemColor,
      required this.unselectedItemColor,
      required this.backgroundColor,
      required this.currentIndex,
      super.key});

  @override
  State<FFNavigationBar> createState() => _FFNavigationBarState();
}

class _FFNavigationBarState extends State<FFNavigationBar> {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: IntrinsicWidth(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.items
                  .map((e) {
                    final index = widget.items.indexOf(e);
                    final isSelected = index == widget.currentIndex;
                    return [
                      GestureDetector(
                        onTap: () {
                          widget.onSelectTab(index);
                        },
                        child: Semantics(
                          label: e.label,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: IconTheme(
                              data: IconThemeData(
                                color: isSelected
                                    ? e.selectedColor ??
                                        widget.selectedItemColor
                                    : e.unselectedColor ??
                                        widget.unselectedItemColor,
                              ),
                              child: isSelected
                                  ? e.icon
                                  : e.unselectedIcon ?? e.icon,
                            ),
                          ),
                        ),
                      ),
                    ];
                  })
                  .flattened
                  .toList()),
        ),
      );
}
