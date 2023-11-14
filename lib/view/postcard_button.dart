import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/log.dart';
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
  final Color? disabledTextColor;
  final double? fontSize;

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
                  style: theme.textTheme.moMASans700Black18.copyWith(
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

class PostcardCustomButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Widget child;
  final Color? disableColor;

  const PostcardCustomButton({
    required this.child,
    super.key,
    this.onTap,
    this.color,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.disableColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const defaultActiveColor = Colors.amber;
    const defaultDisabledColor = AppColor.disabledColor;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? color ?? defaultActiveColor
              : disableColor ?? defaultDisabledColor,
          shadowColor: Colors.transparent,
          disabledForegroundColor: disableColor ?? defaultDisabledColor,
          disabledBackgroundColor: disableColor ?? defaultDisabledColor,
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
    super.key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
  });

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
  });

  @override
  State<PostcardAsyncButton> createState() => _PostcardAsyncButtonState();
}

class _PostcardAsyncButtonState extends State<PostcardAsyncButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) => PostcardButton(
        onTap: () {
          withDebounce(() async {
            setState(() {
              _isProcessing = true;
            });
            try {
              await widget.onTap?.call();
            } catch (e) {
              log.info('Error: $e');
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
