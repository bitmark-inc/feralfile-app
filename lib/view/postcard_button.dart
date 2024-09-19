import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
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
  final Color? disabledTextColor;
  final double? fontSize;
  final TextStyle? textStyle;
  final Widget? icon;
  final double? height;

  const PostcardButton({
    super.key,
    this.onTap,
    this.color,
    this.disabledColor,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.disabledTextColor,
    this.fontSize,
    this.textStyle,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const defaultActiveColor = Colors.amber;
    const defaultDisabledColor = AppColor.disabledColor;
    final backgroundColor = enabled
        ? color ?? defaultActiveColor
        : disabledColor ?? defaultDisabledColor; //theme.auLightGrey;
    return SizedBox(
      width: width,
      height: height,
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
        onPressed: () {
          if (enabled) onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcessing)
                  Container(
                    height: 14,
                    width: 14,
                    margin: const EdgeInsets.only(right: 8),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      strokeWidth: 2,
                    ),
                  ),
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: icon,
                  ),
                Text(
                  text ?? '',
                  style: (textStyle ?? theme.textTheme.moMASans700Black18)
                      .copyWith(
                          color: enabled ? textColor : disabledTextColor,
                          fontSize: fontSize),
                ),
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
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;

  const PostcardOutlineButton({
    super.key,
    this.onTap,
    this.color,
    this.text,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
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
              if (isProcessing)
                Container(
                  height: 14,
                  width: 14,
                  margin: const EdgeInsets.only(right: 8),
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    strokeWidth: 2,
                  ),
                )
              else
                const SizedBox(),
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
    required this.child,
    super.key,
    this.onTap,
    this.color,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
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
              if (isProcessing)
                Container(
                  height: 14,
                  width: 14,
                  margin: const EdgeInsets.only(right: 8),
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    strokeWidth: 2,
                  ),
                )
              else
                const SizedBox(),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PostcardAsyncButton extends StatefulWidget {
  final Function()? onTap;
  final Color? color;
  final Color? disabledColor;
  final String? text;
  final double? width;
  final bool enabled;
  final Color? textColor;
  final Color? disabledTextColor;
  final double? fontSize;
  final String label;

  const PostcardAsyncButton({
    super.key,
    this.onTap,
    this.color,
    this.disabledColor,
    this.text,
    this.width,
    this.enabled = true,
    this.textColor,
    this.disabledTextColor,
    this.fontSize,
    this.label = '',
  });

  @override
  State<PostcardAsyncButton> createState() => _PostcardAsyncButtonState();
}

class _PostcardAsyncButtonState extends State<PostcardAsyncButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) => PostcardButton(
        onTap: () {
          log.info('PostcardAsyncButton onTap');
          withDebounce(key: 'onTap${widget.label}', () async {
            setState(() {
              _isProcessing = true;
            });
            try {
              await widget.onTap?.call();
              if (!mounted) {
                return;
              }
            } catch (e) {
              log.info('Error: $e');
              rethrow;
            } finally {
              setState(() {
                _isProcessing = false;
              });
            }
          });
        },
        color: widget.color,
        width: widget.width,
        enabled: widget.enabled && !_isProcessing,
        text: widget.text,
        textColor: widget.textColor,
        disabledColor: widget.disabledColor,
        disabledTextColor: widget.disabledTextColor,
        fontSize: widget.fontSize,
        isProcessing: _isProcessing,
      );
}
