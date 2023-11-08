import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';

class TransparentDialog extends StatefulWidget {
  final Widget child;
  final Color color;
  final Function(BuildContext context)? afterFirstLayout;
  final Function? onTapOutside;
  final Function? onDispose;

  const TransparentDialog(
      {required this.child,
      this.afterFirstLayout,
      super.key,
      this.color = Colors.transparent,
      this.onTapOutside,
      this.onDispose});

  @override
  State<TransparentDialog> createState() => _TransparentDialogState();
}

class _TransparentDialogState extends State<TransparentDialog>
    with AfterLayoutMixin {
  @override
  Widget build(final BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        widget.onTapOutside?.call();
      },
      child: Container(
        width: width,
        height: height,
        color: widget.color,
        child: widget.child,
      ),
    );
  }

  void onDispose() {
    widget.onDispose?.call();
  }

  @override
  FutureOr<void> afterFirstLayout(final BuildContext context) {
    widget.afterFirstLayout?.call(context);
  }
}
