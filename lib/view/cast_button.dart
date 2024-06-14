import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/stream_device_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FFCastButton extends StatefulWidget {
  final Function(CanvasDevice device)? onDeviceSelected;
  final String? text;
  final String? type;

  const FFCastButton(
      {this.type = '', super.key, this.onDeviceSelected, this.text});

  @override
  State<FFCastButton> createState() => _FFCastButtonState();
}

class _FFCastButtonState extends State<FFCastButton> {
  late CanvasDeviceBloc _canvasDeviceBloc;
  final keyboardManagerKey = GlobalKey<KeyboardManagerWidgetState>();

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: _canvasDeviceBloc,
      builder: (context, state) {
        final isCasting = state.isCasting;
        return GestureDetector(
          onTap: () async {
            await _showStreamAction(context);
          },
          child: Semantics(
            label: 'cast_icon',
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: AppColor.feralFileLightBlue,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.text != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          widget.text!,
                          style: theme.textTheme.ppMori400Black14.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    SvgPicture.asset(
                      'assets/images/cast_icon.svg',
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (isCasting) ...[
                      const SizedBox(
                        width: 3,
                        height: 20,
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(
                          color: AppColor.primaryBlack,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showStreamAction(BuildContext context) async {
    keyboardManagerKey.currentState?.hideKeyboard();
    await UIHelper.showFlexibleDialog(
      context,
      BlocProvider.value(
        value: _canvasDeviceBloc,
        child: StreamDeviceView(
          onDeviceSelected: widget.onDeviceSelected,
        ),
      ),
      isDismissible: true,
    );
  }
}
