import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class SelectGallerySortingWidget extends StatefulWidget {
  final String sortBy;
  const SelectGallerySortingWidget({Key? key, required this.sortBy})
      : super(key: key);

  @override
  State<SelectGallerySortingWidget> createState() =>
      _SelectGallerySortingWidgetState();
}

class _SelectGallerySortingWidgetState
    extends State<SelectGallerySortingWidget> {
  late String _sortBy;
  final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

  @override
  void initState() {
    _sortBy = widget.sortBy;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SORT BY:', style: theme.textTheme.headline5),
          ...GallerySortProperty.getList.map((property) {
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    property,
                    style: theme.textTheme.headline4,
                  ),
                  trailing: RoundCheckBox(
                    // border: Border.,
                    borderColor: Colors.white,
                    uncheckedColor: Colors.transparent,
                    checkedColor: Colors.black,
                    checkedWidget:
                        Icon(Icons.circle, color: Colors.white, size: 16),
                    animationDuration: Duration(milliseconds: 100),
                    isChecked: property == _sortBy,
                    size: 24,
                    onTap: (_) {
                      setState(() {
                        _sortBy = property;
                      });
                    },
                  ),
                ),
                if (property != GallerySortProperty.Chain) ...[
                  addDialogDivider(height: 14),
                ],
              ],
            );
          }).toList(),
          SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "APPLY",
                  onPress: () async {
                    await injector<ConfigurationService>()
                        .setGallerySortBy(_sortBy);

                    Navigator.pop(context);
                  },
                  color: theme.primaryColor,
                  textStyle: TextStyle(
                      color: theme.backgroundColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: "IBMPlexMono"),
                ),
              ),
            ],
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL",
                  style: appTextTheme.button?.copyWith(color: Colors.white))),
        ],
      ),
    );
  }
}
