import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NumberPicker extends StatefulWidget {
  final double value;
  final Function(double) onChange;
  final double min;
  final double max;
  final int divisions;
  final TextStyle? selectedStyle;
  final TextStyle? unselectedStyle;

  const NumberPicker({
    Key? key,
    required this.value,
    required this.onChange,
    required this.min,
    required this.max,
    required this.divisions,
    this.selectedStyle,
    this.unselectedStyle,
  }) : super(key: key);

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late double _selectedValue;
  @override
  void initState() {
    // TODO: implement initState
    _selectedValue = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _numberSlide(
      context: context,
      value: _selectedValue,
      onChange: widget.onChange,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      selectedStyle: widget.selectedStyle,
      unselectedStyle: widget.unselectedStyle,
    );
  }

  Widget _numberSlide({
    required BuildContext context,
    required double value,
    required Function(double) onChange,
    required double min,
    required double max,
    required int divisions,
    TextStyle? selectedStyle,
    TextStyle? unselectedStyle,
  }) {
    final theme = Theme.of(context);
    final numberFormater = NumberFormat('00');
    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4.0,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
            rangeThumbShape: RoundRangeSliderThumbShape(
              enabledThumbRadius: 12.0,
            ),
          ),
          child: Slider(
              value: value,
              onChanged: (value) {
                onChange(value);
                setState(() {
                  _selectedValue = value;
                });
              },
              divisions: divisions,
              min: 12,
              max: 18,
              activeColor: Colors.black.withOpacity(0.2),
              inactiveColor: Colors.black.withOpacity(0.2),
              thumbColor: Colors.black,
              overlayColor: MaterialStateColor.resolveWith(
                (states) => Colors.amber,
              )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //list from a to b
          children:
              List.generate(divisions + 1, (index) => index + min).map((e) {
            return Text(
              '${numberFormater.format(e)} pt',
              style: (e == value)
                  ? (selectedStyle ?? theme.textTheme.ppMori400SupperTeal12)
                  : (unselectedStyle ?? theme.textTheme.ppMori400White12),
            );
          }).toList(),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
