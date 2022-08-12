//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
  final int? maxLines;
  final int? hintMaxLines;

  const AuTextField(
      {Key? key,
      required this.title,
      this.placeholder = "",
      this.isError = false,
      this.expanded = false,
      this.maxLines = 1,
      this.hintMaxLines,
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
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
            decoration: BoxDecoration(
                border: Border.all(
                    color: isError ? AppColorTheme.errorColor : Colors.black)),
            child: Row(
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
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: "AtlasGrotesk",
                                  color: AppColorTheme.secondaryHeaderColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                          subTitleView != null
                              ? const Text(
                                  " | ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "AtlasGrotesk",
                                      color: AppColorTheme.secondaryHeaderColor,
                                      fontWeight: FontWeight.w300),
                                )
                              : const SizedBox(),
                          subTitleView ?? const SizedBox(),
                        ],
                      ),
                      if (maxLines == 1) ...[
                        _textFieldWidget(context)
                      ] else ...[
                        Expanded(
                          child: _textFieldWidget(context),
                        ),
                      ]
                    ],
                  ),
                ),
                suffix ?? const SizedBox(),
              ],
            )));
  }

  Widget _textFieldWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: placeholder,
          hintMaxLines: hintMaxLines,
          hintStyle: const TextStyle(
            fontSize: 16,
            fontFamily: "AtlasGrotesk",
          ),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          // height: 1.2,
          fontFamily: "IBMPlexMono",
          color: Colors.black,
        ),
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onChanged,
      ),
    );
  }
}
