import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/color_picker.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class ArtistDisplaySettingWidget extends StatefulWidget {
  ArtistDisplaySettingWidget(
      {super.key,
      required this.seriesId,
      required this.artistDisplaySetting,
      required this.onSettingChanged});

  final ArtistDisplaySetting? artistDisplaySetting;
  final void Function(ArtistDisplaySetting)? onSettingChanged;
  final String? seriesId;

  @override
  _ArtistDisplaySettingWidgetState createState() =>
      _ArtistDisplaySettingWidgetState();
}

class _ArtistDisplaySettingWidgetState
    extends State<ArtistDisplaySettingWidget> {
  late ArtistArtworkDisplaySettingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ArtistArtworkDisplaySettingBloc();
    _bloc.add(InitArtistArtworkDisplaySettingEvent(
        widget.artistDisplaySetting ?? ArtistDisplaySetting()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtistArtworkDisplaySettingBloc,
        ArtistArtworkDisplaySettingState>(
      bloc: _bloc,
      builder: (context, state) {
        return KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Stack(
                children: [
                  CustomScrollView(shrinkWrap: true, slivers: [
                    SliverToBoxAdapter(
                      child: _header(context),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                          height: 16.0,
                          color: AppColor.primaryBlack,
                          thickness: 2),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8.0),
                    ),
                    SliverToBoxAdapter(
                      child: _orientationSetting(context,
                          value: state.artistDisplaySetting.screenOrientation),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _artFramingSetting(context,
                          value: state.artistDisplaySetting.artFraming),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _backgroundColourSetting(context,
                          value: state.artistDisplaySetting.backgroundColour),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _marginSetting(context,
                          value: state.artistDisplaySetting.margin),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _viewerOverrideSetting(context,
                          value: state.artistDisplaySetting.overridable),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _playbackSetting(context,
                          isAutoPlay: state.artistDisplaySetting.autoPlay,
                          isLoop: state.artistDisplaySetting.loop),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16.0),
                    ),
                    SliverToBoxAdapter(
                      child: _interactableSetting(context,
                          value: state.artistDisplaySetting.interactable),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 60),
                    )
                  ]),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _saveButton(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _saveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PrimaryAsyncButton(
        color: Colors.amber,
        text: 'Save',
        onTap: () {
          _bloc.add(
              SaveArtistArtworkDisplaySettingEvent(seriesId: widget.seriesId));
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Artist Display Setting',
              style: theme.textTheme.ppMori700White14,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: SvgPicture.asset(
            'assets/images/circle_close.svg',
            width: 22,
            height: 22,
          ),
        ),
      ],
    );
  }

  Widget _orientationSetting(BuildContext context, {ScreenOrientation? value}) {
    final selectedIndex = value == ScreenOrientation.landscape ? 1 : 0;
    return ArtistSettingItemWidget(
      settingName: 'Orientation',
      items: [
        DeviceConfigItem(
            title: 'Portrait',
            icon: SvgPicture.asset('assets/images/Rec_portrait.svg'),
            onSelected: () {
              _bloc.add(UpdateOrientationEvent(ScreenOrientation.portrait));
            }),
        DeviceConfigItem(
          title: 'Landscape',
          icon: SvgPicture.asset('assets/images/Rec_landscape.svg'),
          onSelected: () {
            _bloc.add(UpdateOrientationEvent(ScreenOrientation.landscape));
          },
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }

  Widget _artFramingSetting(BuildContext context, {ArtFraming? value}) {
    final selectedIndex = value == ArtFraming.fitToScreen ? 1 : 0;
    return ArtistSettingItemWidget(
      settingName: 'Fitment',
      items: [
        DeviceConfigItem(
          title: 'Fill',
          icon: SvgPicture.asset('assets/images/Rec_landscape.svg',
              colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack, BlendMode.srcIn)),
          onSelected: () {
            _bloc.add(UpdateArtFramingEvent(ArtFraming.cropToFill));
          },
        ),
        DeviceConfigItem(
          title: 'Fit',
          icon: SvgPicture.asset('assets/images/Rec_landscape.svg',
              colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack, BlendMode.srcIn)),
          onSelected: () {
            _bloc.add(UpdateArtFramingEvent(ArtFraming.fitToScreen));
          },
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }

  Widget _backgroundColourSetting(BuildContext context, {Color? value}) {
    return ColorSettingWidget(
      initialColor: value ?? AppColor.primaryBlack,
      onColorChanged: (color) {
        _bloc.add(UpdateBackgroundColourEvent(color));
      },
    );
  }

  Widget _viewerOverrideSetting(BuildContext context, {bool? value}) {
    final selectedIndex = value == true ? 0 : 1;
    final theme = Theme.of(context);
    return ArtistSettingItemWidget(
      settingName: 'Viewer Override',
      items: [
        DeviceConfigItem(
          title: 'Yes',
          icon: Text('Yes', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateOverridableEvent(true));
          },
        ),
        DeviceConfigItem(
          title: 'No',
          icon: Text('No', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateOverridableEvent(false));
          },
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }

  Widget _playbackSetting(BuildContext context,
      {bool? isAutoPlay, bool? isLoop}) {
    final selectedIndex = isAutoPlay == true ? 0 : 1;
    final theme = Theme.of(context);
    return ArtistSettingItemWidget(
      settingName: 'Playback',
      items: [
        DeviceConfigItem(
          title: 'Autoplay',
          icon: Text('Autoplay', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateAutoPlayEvent(true));
          },
        ),
        DeviceConfigItem(
          title: 'Loop',
          icon: Text('Loop', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateLoopEvent(true));
          },
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }

  Widget _interactableSetting(BuildContext context, {bool? value}) {
    final theme = Theme.of(context);
    final selectedIndex = value == true ? 0 : 1;
    return ArtistSettingItemWidget(
      settingName: 'Interactable',
      items: [
        DeviceConfigItem(
          title: 'Enabled',
          icon: Text('Enabled', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateInteractableEvent(true));
          },
        ),
        DeviceConfigItem(
          title: 'Disabled',
          icon: Text('Disabled', style: theme.textTheme.ppMori400Black12),
          onSelected: () {
            _bloc.add(UpdateInteractableEvent(false));
          },
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }

  Widget _marginSetting(BuildContext context, {EdgeInsets? value}) {
    return MarginSettingWidget(
      initialMargin: value ?? EdgeInsets.zero,
      onMarginChanged: (margin) {
        _bloc.add(UpdateMarginEvent(margin));
      },
    );
  }
}

class ArtistSettingItemWidget extends StatefulWidget {
  const ArtistSettingItemWidget(
      {super.key,
      required this.items,
      required this.selectedIndex,
      required this.settingName});

  final List<DeviceConfigItem> items;
  final int selectedIndex;
  final String settingName;

  @override
  _ArtistSettingItemWidgetState createState() =>
      _ArtistSettingItemWidgetState();
}

class _ArtistSettingItemWidgetState extends State<ArtistSettingItemWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItem = widget.items[_selectedIndex];
    return Column(
      children: [
        Row(
          children: [
            Text(widget.settingName, style: theme.textTheme.ppMori400White12),
            const SizedBox(width: 8.0),
            Text(selectedItem.title, style: theme.textTheme.ppMori400Grey12),
          ],
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 168.5 / 42),
          itemCount: widget.items.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                item.onSelected?.call();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: isSelected ? AppColor.white : AppColor.disabledColor,
                ),
                child: Center(
                  child: isSelected
                      ? item.icon
                      : (item.iconOnUnselected ?? item.icon),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ColorSettingWidget extends StatefulWidget {
  const ColorSettingWidget(
      {super.key, required this.onColorChanged, required this.initialColor});

  final Color initialColor;

  final void Function(Color color) onColorChanged;

  @override
  _ColorSettingWidgetState createState() => _ColorSettingWidgetState();
}

class _ColorSettingWidgetState extends State<ColorSettingWidget> {
  late Color _selectedColor;
  late InputTextFieldController _controller;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _controller = InputTextFieldController();
    _controller.text = _selectedColor.toHex();
  }

  @override
  void didUpdateWidget(covariant ColorSettingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedColor = widget.initialColor;
    _controller.text = _selectedColor.toHex();
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
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final color = await UIHelper.showCustomDialog<Color>(
                      context: context,
                      child: ColorPickerView(
                        initialColor: _selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            _selectedColor = color;
                            _controller.text = color.toHex();
                          });
                          widget.onColorChanged(_selectedColor);
                        },
                      ));
                  log.info('Color: $color');
                },
                child: AspectRatio(
                  aspectRatio: 168.5 / 42,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: _selectedColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(child: _colorTextField(context, _selectedColor))
          ],
        )
      ],
    );
  }

  Widget _colorTextField(BuildContext context, Color color) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColor.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.ppMori400Black12,
      onSubmitted: (value) {
        final color = ColorExt.fromHex(value);
        setState(() {
          _selectedColor = color;
        });
        widget.onColorChanged(color);
      },
    );
  }
}

extension ColorExt on Color {
  // Convert a color to a hex string without the alpha value
  // example: Colors.white.toHex() => '#FFFFFF'

  String toHex() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Convert a hex string to a color
  // example: Color.fromHex('#FFFFFF') => Colors.white
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class MarginSettingWidget extends StatefulWidget {
  const MarginSettingWidget(
      {super.key, required this.onMarginChanged, required this.initialMargin});

  final EdgeInsets initialMargin;

  final void Function(EdgeInsets margin) onMarginChanged;

  @override
  _MarginSettingWidgetState createState() => _MarginSettingWidgetState();
}

class _MarginSettingWidgetState extends State<MarginSettingWidget> {
  late EdgeInsets _selectedMargin;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedMargin = widget.initialMargin;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Margin',
                  style: Theme.of(context).textTheme.ppMori400White12),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 79.25 / 42),
          itemCount: 4,
          itemBuilder: (BuildContext context, int index) {
            final isSelected = _selectedIndex == index;
            final marginValue = getMarginValue(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: isSelected ? AppColor.white : AppColor.disabledColor,
                ),
                child: Center(
                  child: Text(
                    '${marginValue.toInt()}%',
                    style: Theme.of(context).textTheme.ppMori400Black12,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
        _slider(context),
      ],
    );
  }

  double getMarginValue(int index) {
    switch (index) {
      case 0:
        return _selectedMargin.left;
      case 1:
        return _selectedMargin.top;
      case 2:
        return _selectedMargin.right;
      case 3:
        return _selectedMargin.bottom;
      default:
        return 0;
    }
  }

  void setMarginValue(int index, double value) {
    EdgeInsets margin = _selectedMargin;
    switch (index) {
      case 0:
        margin = margin.copyWith(left: value);
      case 1:
        margin = margin.copyWith(top: value);
      case 2:
        margin = margin.copyWith(right: value);
      case 3:
        margin = margin.copyWith(bottom: value);
      default:
        break;
    }
    widget.onMarginChanged(margin);
    setState(() {
      _selectedMargin = margin;
    });
  }

  Widget _slider(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: AppColor.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16.0),
      child: FFHorizontalSlider(
        value: getMarginValue(_selectedIndex),
        min: 0,
        max: 100,
        interval: 50,
        onChanged: (value) {
          setMarginValue(_selectedIndex, value);
        },
      ),
    );
  }
}

class FFHorizontalSlider extends StatefulWidget {
  const FFHorizontalSlider(
      {super.key,
      required this.min,
      required this.max,
      required this.value,
      required this.interval,
      required this.onChanged});

  final double min;
  final double max;
  final double value;
  final double interval;
  final Function(double) onChanged;

  @override
  _FFHorizontalSliderState createState() => _FFHorizontalSliderState();
}

class _FFHorizontalSliderState extends State<FFHorizontalSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant FFHorizontalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SfSliderTheme(
      data: const SfSliderThemeData(
          activeTrackHeight: 2,
          inactiveTrackHeight: 2,
          tickSize: Size(2, 24),
          tickOffset: Offset(0, -12),
          activeTickColor: AppColor.primaryBlack,
          inactiveTickColor: AppColor.primaryBlack,
          overlayColor: Colors.green,
          overlayRadius: 0),
      child: SfSlider(
        value: _value,
        min: widget.min,
        max: widget.max,
        interval: 50,
        // showTicks: true,
        activeColor: AppColor.primaryBlack,
        inactiveColor: AppColor.primaryBlack,
        showDividers: true,
        // tickShape: const CustomSfTickShape(),
        stepSize: 1,
        showTicks: true,
        onChanged: (v) {
          final value = v as double;
          setState(() {
            _value = value;
          });
          widget.onChanged(value);
        },
      ),
    );
  }
}
