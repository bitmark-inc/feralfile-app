import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FFNavigationBarItem {
  final Widget icon;
  final String label;

  const FFNavigationBarItem({
    required this.icon,
    required this.label,
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
                  .map((e) => [
                        GestureDetector(
                          onTap: () {
                            final index = widget.items.indexOf(e);

                            widget.onSelectTab(index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: IconTheme(
                              data: IconThemeData(
                                color: widget.currentIndex ==
                                        widget.items.indexOf(e)
                                    ? widget.selectedItemColor
                                    : widget.unselectedItemColor,
                              ),
                              child: e.icon,
                            ),
                          ),
                        ),
                      ])
                  .flattened
                  .toList()),
        ),
      );
}
