import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';

class AuTextField extends StatelessWidget {
  final String title;
  final String placeholder;
  final bool isError;
  final bool expanded;
  final TextEditingController controller;
  final Widget? subTitleView;
  final Widget? suffix;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const AuTextField(
      {Key? key,
      required this.title,
      this.placeholder = "",
      this.isError = false,
      this.expanded = false,
      required this.controller,
      this.subTitleView,
      this.suffix,
      this.keyboardType = TextInputType.text,
      this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: expanded ? 1 : 0,
        child: Container(
            padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
            decoration: BoxDecoration(
                border: Border.all(
                    color: isError ? AppColorTheme.errorColor : Colors.black)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (title.isNotEmpty) ...[
                            Text(
                              title,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: "AtlasGrotesk",
                                  color: AppColorTheme.secondaryHeaderColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                          this.subTitleView != null
                              ? Text(
                                  " | ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "AtlasGrotesk",
                                      color: AppColorTheme.secondaryHeaderColor,
                                      fontWeight: FontWeight.w300),
                                )
                              : SizedBox(),
                          this.subTitleView ?? SizedBox(),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: placeholder,
                          ),
                          keyboardType: keyboardType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            // height: 1.2,
                            fontFamily: "IBMPlexMono",
                            color: Colors.black,
                          ),
                          controller: controller,
                          onChanged: onChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                suffix ?? SizedBox(),
              ],
            )));
  }
}
