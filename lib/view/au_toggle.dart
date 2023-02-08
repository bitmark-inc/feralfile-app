//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class AuToggle extends StatelessWidget {
  final Function(bool value)? onToggle;
  final bool value;

  const AuToggle({
    Key? key,
    required this.value,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      height: 25,
      width: 48,
      toggleSize: 19.2,
      padding: 2,
      value: value,
      onToggle: onToggle ?? (bool p) {},
      activeColor: AppColor.auSuperTeal,
      toggleColor: AppColor.primaryBlack,
      inactiveColor: AppColor.auLightGrey,
      inactiveToggleColor: AppColor.greyMedium,
    );
  }
}
