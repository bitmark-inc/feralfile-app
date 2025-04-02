import 'package:autonomy_flutter/util/style.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/svg.dart';

class ColorPickerView extends StatefulWidget {
  const ColorPickerView(
      {super.key, required this.onColorChanged, required this.initialColor});

  final Color initialColor;

  final void Function(Color) onColorChanged;

  @override
  _ColorPickerViewState createState() => _ColorPickerViewState();
}

class _ColorPickerViewState extends State<ColorPickerView> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  void didUpdateWidget(covariant ColorPickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Background Color',
                  style: Theme.of(context).textTheme.ppMori400White12),
            ),
            const SizedBox(width: 8.0),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(_selectedColor);
              },
              child: SvgPicture.asset(
                'assets/images/circle_close.svg',
                width: 22,
                height: 22,
              ),
            )
          ],
        ),
        addDivider(height: 20),
        FFColorPicker(
          pickerColor: _selectedColor,
          paletteType: PaletteType.hslWithSaturation,
          enableAlpha: false,
          labelTypes: [ColorLabelType.rgb],
          displayThumbColor: true,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
            widget.onColorChanged(color);
          },
        ),
      ],
    );
  }
}

/// The default layout of Color Picker.
class FFColorPicker extends StatefulWidget {
  const FFColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerHsvColor,
    this.onHsvColorChanged,
    this.paletteType = PaletteType.hsvWithHue,
    this.enableAlpha = true,
    @Deprecated('Use empty list in [labelTypes] to disable label.')
    this.showLabel = true,
    this.labelTypes = const [
      ColorLabelType.rgb,
      ColorLabelType.hsv,
      ColorLabelType.hsl
    ],
    @Deprecated(
        'Use Theme.of(context).textTheme.bodyText1 & 2 to alter text style.')
    this.labelTextStyle,
    this.displayThumbColor = false,
    this.portraitOnly = false,
    this.colorPickerWidth = 300.0,
    this.pickerAreaHeightPercent = 1.0,
    this.pickerAreaBorderRadius = const BorderRadius.all(Radius.zero),
    this.hexInputBar = false,
    this.hexInputController,
    this.colorHistory,
    this.onHistoryChanged,
  }) : super(key: key);

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final HSVColor? pickerHsvColor;
  final ValueChanged<HSVColor>? onHsvColorChanged;
  final PaletteType paletteType;
  final bool enableAlpha;
  final bool showLabel;
  final List<ColorLabelType> labelTypes;
  final TextStyle? labelTextStyle;
  final bool displayThumbColor;
  final bool portraitOnly;
  final double colorPickerWidth;
  final double pickerAreaHeightPercent;
  final BorderRadius pickerAreaBorderRadius;
  final bool hexInputBar;

  /// Allows setting the color using text input, via [TextEditingController].
  ///
  /// Listens to [String] input and trying to convert it to the valid [Color].
  /// Contains basic validator, that requires final input to be provided
  /// in one of those formats:
  ///
  /// * RGB
  /// * #RGB
  /// * RRGGBB
  /// * #RRGGBB
  /// * AARRGGBB
  /// * #AARRGGBB
  ///
  /// Where: A stands for Alpha, R for Red, G for Green, and B for blue color.
  /// It will only accept 3/6/8 long HEXs with an optional hash (`#`) at the beginning.
  /// Allowed characters are Latin A-F case insensitive and numbers 0-9.
  /// It does respect the [enableAlpha] flag, so if alpha is disabled, all inputs
  /// with transparency are also converted to non-transparent color values.
  /// ```dart
  ///   MaterialButton(
  ///    elevation: 3.0,
  ///    onPressed: () {
  ///      // The initial value can be provided directly to the controller.
  ///      final textController =
  ///          TextEditingController(text: '#2F19DB');
  ///      showDialog(
  ///        context: context,
  ///        builder: (BuildContext context) {
  ///          return AlertDialog(
  ///            scrollable: true,
  ///            titlePadding: const EdgeInsets.all(0.0),
  ///            contentPadding: const EdgeInsets.all(0.0),
  ///            content: Column(
  ///              children: [
  ///                ColorPicker(
  ///                  pickerColor: currentColor,
  ///                  onColorChanged: changeColor,
  ///                  colorPickerWidth: 300.0,
  ///                  pickerAreaHeightPercent: 0.7,
  ///                  enableAlpha:
  ///                      true, // hexInputController will respect it too.
  ///                  displayThumbColor: true,
  ///                  showLabel: true,
  ///                  paletteType: PaletteType.hsv,
  ///                  pickerAreaBorderRadius: const BorderRadius.only(
  ///                    topLeft: const Radius.circular(2.0),
  ///                    topRight: const Radius.circular(2.0),
  ///                  ),
  ///                  hexInputController: textController, // <- here
  ///                  portraitOnly: true,
  ///                ),
  ///                Padding(
  ///                  padding: const EdgeInsets.all(16),
  ///                  /* It can be any text field, for example:
  ///                  * TextField
  ///                  * TextFormField
  ///                  * CupertinoTextField
  ///                  * EditableText
  ///                  * any text field from 3-rd party package
  ///                  * your own text field
  ///                  so basically anything that supports/uses
  ///                  a TextEditingController for an editable text.
  ///                  */
  ///                  child: CupertinoTextField(
  ///                    controller: textController,
  ///                    // Everything below is purely optional.
  ///                    prefix: Padding(
  ///                      padding: const EdgeInsets.only(left: 8),
  ///                      child: const Icon(Icons.tag),
  ///                    ),
  ///                    suffix: IconButton(
  ///                      icon:
  ///                          const Icon(Icons.content_paste_rounded),
  ///                      onPressed: () async =>
  ///                          copyToClipboard(textController.text),
  ///                    ),
  ///                    autofocus: true,
  ///                    maxLength: 9,
  ///                    inputFormatters: [
  ///                      // Any custom input formatter can be passed
  ///                      // here or use any Form validator you want.
  ///                      UpperCaseTextFormatter(),
  ///                      FilteringTextInputFormatter.allow(
  ///                          RegExp(kValidHexPattern)),
  ///                    ],
  ///                  ),
  ///                )
  ///              ],
  ///            ),
  ///          );
  ///        },
  ///      );
  ///    },
  ///    child: const Text('Change me via text input'),
  ///    color: currentColor,
  ///    textColor: useWhiteForeground(currentColor)
  ///        ? const Color(0xffffffff)
  ///        : const Color(0xff000000),
  ///  ),
  /// ```
  ///
  /// Do not forget to `dispose()` your [TextEditingController] if you creating
  /// it inside any kind of [StatefulWidget]'s [State].
  /// Reference: https://en.wikipedia.org/wiki/Web_colors#Hex_triplet
  final TextEditingController? hexInputController;
  final List<Color>? colorHistory;
  final ValueChanged<List<Color>>? onHistoryChanged;

  @override
  State<FFColorPicker> createState() => _FFColorPickerState();
}

class _FFColorPickerState extends State<FFColorPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);
  List<Color> colorHistory = [];

  @override
  void initState() {
    currentHsvColor = (widget.pickerHsvColor != null)
        ? widget.pickerHsvColor as HSVColor
        : HSVColor.fromColor(widget.pickerColor);
    // If there's no initial text in `hexInputController`,
    if (widget.hexInputController?.text.isEmpty == true) {
      // set it to the current's color HEX value.
      widget.hexInputController?.text = colorToHex(
        currentHsvColor.toColor(),
        enableAlpha: widget.enableAlpha,
      );
    }
    // Listen to the text input, If there is an `hexInputController` provided.
    widget.hexInputController?.addListener(colorPickerTextInputListener);
    if (widget.colorHistory != null && widget.onHistoryChanged != null) {
      colorHistory = widget.colorHistory ?? [];
    }
    super.initState();
  }

  @override
  void didUpdateWidget(FFColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = (widget.pickerHsvColor != null)
        ? widget.pickerHsvColor as HSVColor
        : HSVColor.fromColor(widget.pickerColor);
  }

  void colorPickerTextInputListener() {
    // It can't be null really, since it's only listening if the controller
    // is provided, but it may help to calm the Dart analyzer in the future.
    if (widget.hexInputController == null) return;
    // If a user is inserting/typing any text — try to get the color value from it,
    // and interpret its transparency, dependent on the widget's settings.
    final Color? color = colorFromHex(widget.hexInputController!.text,
        enableAlpha: widget.enableAlpha);
    // If it's the valid color:
    if (color != null) {
      // set it as the current color and
      setState(() => currentHsvColor = HSVColor.fromColor(color));
      // notify with a callback.
      widget.onColorChanged(color);
      if (widget.onHsvColorChanged != null)
        widget.onHsvColorChanged!(currentHsvColor);
    }
  }

  @override
  void dispose() {
    widget.hexInputController?.removeListener(colorPickerTextInputListener);
    super.dispose();
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(
      trackType,
      currentHsvColor,
      (HSVColor color) {
        // Update text in `hexInputController` if provided.
        widget.hexInputController?.text =
            colorToHex(color.toColor(), enableAlpha: widget.enableAlpha);
        setState(() => currentHsvColor = color);
        widget.onColorChanged(currentHsvColor.toColor());
        if (widget.onHsvColorChanged != null)
          widget.onHsvColorChanged!(currentHsvColor);
      },
      displayThumbColor: widget.displayThumbColor,
    );
  }

  void onColorChanging(HSVColor color) {
    // Update text in `hexInputController` if provided.
    widget.hexInputController?.text =
        colorToHex(color.toColor(), enableAlpha: widget.enableAlpha);
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor.toColor());
    if (widget.onHsvColorChanged != null)
      widget.onHsvColorChanged!(currentHsvColor);
  }

  Widget colorPicker() {
    return ClipRRect(
      borderRadius: widget.pickerAreaBorderRadius,
      child: Padding(
        padding:
            EdgeInsets.all(widget.paletteType == PaletteType.hueWheel ? 10 : 0),
        child: ColorPickerArea(
            currentHsvColor, onColorChanging, widget.paletteType),
      ),
    );
  }

  Widget sliderByPaletteType() {
    return colorPickerSlider(TrackType.saturationForHSL);
  }

  Widget _colorInfo(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final texts = ['RGB', '${color.r}', '${color.g}', '${color.b}'];
    return Row(
      children: [
        for (int i = 0; i < texts.length; i++) ...[
          Expanded(
            child: AspectRatio(
              aspectRatio: 79.25 / 42,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    texts[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.ppMori400Black12,
                  ),
                ),
              ),
            ),
          ),
          if (i < texts.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: widget.colorPickerWidth,
          height: widget.colorPickerWidth * widget.pickerAreaHeightPercent,
          child: colorPicker(),
        ),
        const SizedBox(height: 12.0),
        _colorInfo(context, currentHsvColor.toColor()),
        Padding(
          padding: const EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () => setState(() {
                  if (widget.onHistoryChanged != null &&
                      !colorHistory.contains(currentHsvColor.toColor())) {
                    colorHistory.add(currentHsvColor.toColor());
                    widget.onHistoryChanged!(colorHistory);
                  }
                }),
                child: ColorIndicator(currentHsvColor),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                        height: 40.0,
                        width: widget.colorPickerWidth - 75.0,
                        child: sliderByPaletteType()),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (colorHistory.isNotEmpty)
          SizedBox(
            width: widget.colorPickerWidth,
            height: 50,
            child:
                ListView(scrollDirection: Axis.horizontal, children: <Widget>[
              for (Color color in colorHistory)
                Padding(
                  key: Key(color.hashCode.toString()),
                  padding: const EdgeInsets.fromLTRB(15, 0, 0, 10),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onColorChanging(HSVColor.fromColor(color)),
                      child: ColorIndicator(HSVColor.fromColor(color),
                          width: 30, height: 30),
                    ),
                  ),
                ),
              const SizedBox(width: 15),
            ]),
          ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
