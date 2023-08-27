import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:flutter/material.dart';

class PostcardButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final Color? disabledColor;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final double? fontSize;

  const PostcardButton({
    Key? key,
    this.onTap,
    this.color,
    this.disabledColor,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const defaultActiveColor = Colors.amber;
    final defaultDisabledColor = theme.auLightGrey;
    final backgroundColor = enabled
        ? color ?? defaultActiveColor
        : disabledColor ?? defaultDisabledColor; //theme.auLightGrey;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shadowColor: Colors.transparent,
          disabledForegroundColor: disabledColor ?? defaultDisabledColor,
          disabledBackgroundColor: disabledColor ?? defaultDisabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                  style: theme.textTheme.moMASans700Black14
                      .copyWith(color: textColor, fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostcardCustomButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Widget child;

  const PostcardCustomButton({
    Key? key,
    this.onTap,
    this.color,
    this.width,
    required this.child,
    this.enabled = true,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const defaultActiveColor = Colors.amber;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? color ?? defaultActiveColor : theme.auLightGrey,
          shadowColor: Colors.transparent,
          disabledForegroundColor: theme.auLightGrey,
          disabledBackgroundColor: theme.auLightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostcardOutlineButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;

  const PostcardOutlineButton({
    Key? key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
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
            borderRadius: BorderRadius.circular(0),
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
                  style: theme.textTheme.moMASans400White14.copyWith(
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

class PostcardCustomOutlineButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final Widget child;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;

  const PostcardCustomOutlineButton({
    Key? key,
    this.onTap,
    this.color,
    required this.child,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
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
            borderRadius: BorderRadius.circular(0),
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
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
