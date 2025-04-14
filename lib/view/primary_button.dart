import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final Color? disabledColor;
  final String? text;
  final Color? textColor;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? indicatorColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? elevatedPadding;
  final double borderRadius;
  final Color? borderColor;

  const PrimaryButton({
    super.key,
    this.onTap,
    this.color,
    this.disabledColor,
    this.text,
    this.textColor,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.indicatorColor,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
    this.elevatedPadding,
    this.borderRadius = 32,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = this.disabledColor ?? AppColor.disabledColor;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? color ?? AppColor.feralFileLightBlue : disabledColor,
          padding: elevatedPadding,
          shadowColor: Colors.transparent,
          disabledForegroundColor: disabledColor,
          disabledBackgroundColor: disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
            ),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: padding,
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
                      color: indicatorColor ?? theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const SizedBox(),
                Text(
                  text ?? '',
                  style: theme.textTheme.ppMori400Black14
                      .copyWith(color: textColor),
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
    super.key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
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
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: padding,
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
  final Color? textColor;
  final double? width;
  final bool enabled;
  final String? processingText;
  final Color? borderColor;

  const PrimaryAsyncButton(
      {super.key,
      this.onTap,
      this.color,
      this.textColor,
      this.text,
      this.width,
      this.enabled = true,
      this.borderColor,
      this.processingText});

  @override
  State<PrimaryAsyncButton> createState() => _PrimaryAsyncButtonState();
}

class _PrimaryAsyncButtonState extends State<PrimaryAsyncButton> {
  bool _isProcessing = false;

  late final String randomKey;

  @override
  void initState() {
    super.initState();
    randomKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) => PrimaryButton(
        onTap: () {
          withDebounce(
            key: randomKey,
            () async {
              setState(() {
                _isProcessing = true;
              });
              await widget.onTap?.call();
              if (!mounted) {
                return;
              }
              setState(() {
                _isProcessing = false;
              });
            },
          );
        },
        color: widget.color,
        text: _isProcessing && widget.processingText != null
            ? widget.processingText
            : widget.text,
        textColor: widget.textColor,
        borderColor: widget.borderColor,
        width: widget.width,
        enabled: widget.enabled && !_isProcessing,
        isProcessing: _isProcessing,
      );
}

class TextAsyncButton extends StatefulWidget {
  const TextAsyncButton({
    required this.color,
    super.key,
    this.onTap,
    this.text,
    this.processingText,
  });

  final dynamic Function()? onTap;
  final Color color;
  final String? text;
  final String? processingText;

  @override
  State<TextAsyncButton> createState() => _TextAsyncButtonState();
}

class _TextAsyncButtonState extends State<TextAsyncButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isProcessing)
            Container(
              height: 14,
              width: 14,
              margin: const EdgeInsets.only(right: 8),
              child: CircularProgressIndicator(
                color: widget.color,
                backgroundColor: Colors.transparent,
                strokeWidth: 2,
              ),
            ),
          TextButton(
            onPressed: () {
              withDebounce(
                () async {
                  setState(() {
                    _isProcessing = true;
                  });
                  await widget.onTap?.call();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _isProcessing = false;
                  });
                },
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isProcessing ? widget.processingText ?? '' : widget.text ?? '',
              style: Theme.of(context)
                  .textTheme
                  .ppMori400Black14
                  .copyWith(color: widget.color),
            ),
          ),
        ],
      );
}
