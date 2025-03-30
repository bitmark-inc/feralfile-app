import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NowDisplaySettingView extends StatefulWidget {
  const NowDisplaySettingView({required this.settings, super.key});
  final DisplaySettings settings;

  @override
  State<NowDisplaySettingView> createState() => _NowDisplaySettingViewState();
}

class _NowDisplaySettingViewState extends State<NowDisplaySettingView> {
  late ArtFraming viewMode;

  @override
  void initState() {
    super.initState();
    viewMode = widget.settings.viewMode;
  }

  List<OptionItem> _settingOptions() {
    return [
      OptionItem(
        title: 'Rotate',
        icon: SvgPicture.asset(
          'assets/images/icon_rotate_white.svg',
        ),
        onTap: () {
          // Handle rotate
        },
      ),
      OptionItem(
        title: 'Fit',
        icon: SvgPicture.asset(
          viewMode == ArtFraming.fitToScreen
              ? 'assets/images/radio_selected.svg'
              : 'assets/images/radio_unselected.svg',
        ),
        onTap: () {
          setState(() {
            viewMode = ArtFraming.fitToScreen;
          });
        },
      ),
      OptionItem(
        title: 'Fill',
        icon: SvgPicture.asset(
          viewMode == ArtFraming.cropToFill
              ? 'assets/images/radio_selected.svg'
              : 'assets/images/radio_unselected.svg',
        ),
        onTap: () {
          setState(() {
            viewMode = ArtFraming.cropToFill;
          });
        },
      ),
      OptionItem(
        builder: (context, item) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.white),
                borderRadius: BorderRadius.circular(47),
              ),
              child: Center(
                child: Text(
                  'configure_device'.tr(),
                  style: Theme.of(context).textTheme.ppMori400White14,
                ),
              ),
            ),
          );
        },
        onTap: () {
          // Handle configure device
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final option = _settingOptions()[index];
            if (option.builder != null) {
              return option.builder!.call(context, option);
            }
            return DrawerItem(
              item: option,
              color: AppColor.white,
            );
          },
          itemCount: _settingOptions().length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColor.primaryBlack,
          ),
        ),
      ],
    );
  }
}
