import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;

  const PrimaryButton({
    Key? key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? color ?? theme.auSuperTeal : theme.auLightGrey,
          shadowColor: Colors.transparent,
          disabledForegroundColor: theme.auLightGrey,
          disabledBackgroundColor: theme.auLightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? Container(
                        height: 14.0,
                        width: 14.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const SizedBox(),
                Text(
                  text ?? '',
                  style: theme.textTheme.ppMori400Black14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsets padding;

  const OutlineButton({
    Key? key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.auGreyBackground,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor ?? Colors.white),
            borderRadius: BorderRadius.circular(32.0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: padding,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? Container(
                        height: 14.0,
                        width: 14.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const SizedBox(),
                Text(
                  text ?? '',
                  style: theme.textTheme.ppMori400White14.copyWith(
                      color: textColor ??
                          (!enabled ? AppColor.disabledColor : null)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryAsyncButton extends StatefulWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool enabled;

  const PrimaryAsyncButton(
      {Key? key,
      this.onTap,
      this.color,
      this.text,
      this.width,
      this.enabled = true})
      : super(key: key);

  @override
  State<PrimaryAsyncButton> createState() => _PrimaryAsyncButtonState();
}

class _PrimaryAsyncButtonState extends State<PrimaryAsyncButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onTap: () async {
        setState(() {
          _isProcessing = true;
        });
        await widget.onTap?.call();
        setState(() {
          _isProcessing = false;
        });
      },
      color: widget.color,
      text: widget.text,
      width: widget.width,
      enabled: widget.enabled,
      isProcessing: _isProcessing,
    );
  }
}
