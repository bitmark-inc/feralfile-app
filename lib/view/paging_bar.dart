//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PagingBar extends StatelessWidget {
  final Function(String value) onTap;
  final String? selectedCharacter;

  const PagingBar({required this.onTap, super.key, this.selectedCharacter});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int characterWidth = (width / listCharacters.length).floor() - 2;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: listCharacters
            .map((e) => GestureDetector(
                  onTap: () => onTap(e),
                  child: SizedBox(
                    width: characterWidth.toDouble(),
                    child: AutoSizeText(
                      e,
                      style: theme.textTheme.ppMori400Grey14.copyWith(
                          color: e == selectedCharacter
                              ? AppColor.white
                              : AppColor.auQuickSilver),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
