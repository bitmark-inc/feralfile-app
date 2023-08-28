import 'dart:math';

import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:undo/undo.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

import 'hand_signature_page.dart';

class DesignStampPage extends StatefulWidget {
  static const String tag = 'design_stamp_screen';
  final DesignStampPayload payload;

  const DesignStampPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<DesignStampPage> createState() => _DesignStampPageState();
}

class _DesignStampPageState extends State<DesignStampPage> {
  List<Color?> _rectColors = List<Color?>.filled(100, null);
  Color _selectedColor = AppColor.primaryBlack;
  String _location = "MoMA";
  late String _date;
  final WidgetsToImageController _controller = WidgetsToImageController();
  bool _line = true;
  late SimpleStack _undoController;

  @override
  void initState() {
    super.initState();
    _location = widget.payload.location.address;

    _undoController = SimpleStack<List<Color?>>(
      List<Color?>.filled(100, null),
      onUpdate: (val) {
        setState(
          () {
            _rectColors = val.toList();
          },
        );
      },
    );

    // date now dd-mm-yy
    final dateTimeFormater = DateFormat('dd-MM-yyyy');
    _date = dateTimeFormater.format(DateTime.now());
    stampColors.shuffle();
    _selectedColor = stampColors[0];
  }

  @override
  void dispose() {
    _undoController.clearHistory();
    super.dispose();
  }

  String selectLocation(String? first, String? second) {
    if (first != null && first.isNotEmpty) {
      return first;
    } else if (second != null && second.isNotEmpty) {
      return second;
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    final cellSize = ((size - 60.0) / 10.0).floor();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar: getBackAppBar(
        context,
        title: "design_your_stamp".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
        isWhite: false,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: ResponsiveLayout.padding),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "all_cells_must_be_filled".tr(),
                          style: theme.textTheme.moMASans400Grey12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        color: AppColor.white,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  WidgetsToImage(
                                    controller: _controller,
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        // update rectColors using details.localPosition and selectedColor
                                        final x = details.localPosition.dx;
                                        final y = details.localPosition.dy;
                                        _paint(x, y, cellSize);
                                      },
                                      onPanUpdate: (details) {
                                        // update rectColors using details.localPosition and selectedColor
                                        final x = details.localPosition.dx;
                                        final y = details.localPosition.dy;
                                        _paint(x, y, cellSize);
                                      },
                                      onPanEnd: (details) {
                                        _modifyStackUndo();
                                      },
                                      onTapUp: (details) {
                                        _modifyStackUndo();
                                      },
                                      child: Container(
                                        color: AppColor.white,
                                        child: SizedBox(
                                          width: cellSize * 10,
                                          height: cellSize * 10,
                                          child: CustomPaint(
                                            painter: StampPainter(
                                                rectColors: _rectColors,
                                                line: _line),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _stampLocation(context, cellSize)
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: colorPicker(),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                children: [
                                  PostcardCustomOutlineButton(
                                    onTap: !_undoController.canUndo
                                        ? null
                                        : () {
                                            if (mounted) {
                                              setState(() {
                                                _undoController.undo();
                                              });
                                            }
                                          },
                                    width: 52,
                                    color: AppColor.white,
                                    borderColor: AppColor.greyMedium,
                                    textColor: AppColor.greyMedium,
                                    child: SvgPicture.asset(
                                      "assets/images/Undo.svg",
                                      width: 16,
                                      colorFilter: const ColorFilter.mode(
                                          AppColor.greyMedium, BlendMode.srcIn),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PostcardOutlineButton(
                                      onTap: () {
                                        setState(() {
                                          fillRandomColor();
                                        });
                                      },
                                      text: "randomize".tr(),
                                      textColor: AppColor.greyMedium,
                                      color: AppColor.white,
                                      borderColor: AppColor.greyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PostcardOutlineButton(
                                      onTap: () {
                                        setState(() {
                                          _line = true;
                                          _rectColors =
                                              List<Color?>.filled(100, null);
                                        });
                                        _modifyStackUndo();
                                      },
                                      text: "clear_all".tr(),
                                      textColor: AppColor.greyMedium,
                                      borderColor: AppColor.greyMedium,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostcardButton(
                              text: "stamp_postcard".tr(),
                              onTap: _rectColors
                                      .any((element) => element == null)
                                  ? null
                                  : () async {
                                      setState(() {
                                        _line = false;
                                      });
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () async {
                                          final bytes =
                                              await _controller.capture();
                                          if (!mounted) return;
                                          Navigator.of(context).pushNamed(
                                              HandSignaturePage
                                                  .handSignaturePage,
                                              arguments: HandSignaturePayload(
                                                  bytes!,
                                                  widget.payload.asset,
                                                  widget.payload.location
                                                      .position,
                                                  _location));
                                        },
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _paint(double x, double y, int cellSize) {
    if (x < 0 || x > cellSize * 10 || y < 0 || y > cellSize * 10) {
      return;
    }

    final index = y ~/ cellSize + (x ~/ cellSize) * 10;
    if (index >= 0 && index < 100) {
      setState(() {
        _rectColors[index] = _selectedColor;
      });
    }
  }

  Widget _stampLocation(BuildContext context, int cellSize) {
    final theme = Theme.of(context);
    return Container(
      color: AppColor.primaryBlack,
      child: SizedBox(
        height: cellSize * 1.0,
        width: cellSize * 10,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _location,
                  style: theme.textTheme.moMASans400White14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _date,
                style: theme.textTheme.moMASans400White14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> stampColors = [
    MomaPallet.pink,
    MomaPallet.red,
    MomaPallet.brick,
    MomaPallet.lightBrick,
    MomaPallet.orange,
    MomaPallet.lightYellow,
    MomaPallet.bananaYellow,
    MomaPallet.green,
    MomaPallet.riverGreen,
    MomaPallet.cloudBlue,
    MomaPallet.blue,
    MomaPallet.purple,
    MomaPallet.black,
    MomaPallet.white,
  ];

  void _modifyStackUndo() {
    final oldState = _undoController.state as List<Color?>;
    if (!_compareListColor(oldState, _rectColors)) {
      _undoController.modify(_rectColors);
    }
  }

  bool _compareListColor(List<Color?> oldState, List<Color?> newState) {
    for (var i = 0; i < oldState.length; i++) {
      if (oldState[i] != newState[i]) {
        return false;
      }
    }
    return true;
  }

  // function to fill rectColors with random color from stampColors
  void fillRandomColor() {
    stampColors.shuffle();
    for (var i = 0; i < _rectColors.length; i++) {
      final m = Random().nextInt(stampColors.length - 1);
      _rectColors[i] = stampColors[m];
    }
    _modifyStackUndo();
  }

  // color picker update selectedColor using horizontal listview, each item is a circle with color, selectedColor is white border
  Widget colorPicker() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stampColors.length,
        itemBuilder: (context, index) {
          final color = stampColors[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color
                      ? AppColor.primaryBlack
                      : color == MomaPallet.white
                          ? AppColor.auGrey
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StampPainter extends CustomPainter {
  StampPainter({required this.rectColors, this.line = true});

  bool line;
  List<Color?> rectColors;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = min(size.width, size.width) / 10.0;

    // draw 9 vertical lines and 9 horizontal lines
    if (line) {
      final paint = Paint()
        ..color = AppColor.auLightGrey
        ..strokeWidth = 0.3;
      for (var i = 0; i <= 10; i++) {
        canvas.drawLine(Offset(i * cellSize, 0),
            Offset(i * cellSize, cellSize * 10), paint);
        canvas.drawLine(
            Offset(0, i * cellSize), Offset(size.width, i * cellSize), paint);
      }
    }

    // draw 100 rectangles if color is not null
    for (var i = 0; i < 10; i++) {
      for (var j = 0; j < 10; j++) {
        final color = rectColors[i * 10 + j];
        final borderWidth = i == 9 ? 0 : 0.3;
        final borderHeight = j == 9 ? 0 : 0.3;
        if (color != null) {
          final rect = Rect.fromLTWH(i * cellSize, j * cellSize,
              cellSize + borderWidth, cellSize + borderHeight);
          canvas.drawRect(rect, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant StampPainter oldDelegate) {
    return true;
  }
}

class DesignStampPayload {
  final AssetToken asset;
  final GeoLocation location;

  DesignStampPayload(this.asset, this.location);
}
