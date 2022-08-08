//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';

class BadgeView extends StatelessWidget {
  final int number;
  const BadgeView({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white)),
        alignment: Alignment.center,
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: "AtlasGrotesk",
              fontWeight: FontWeight.w700,
              height: 1.33),
        ));
  }
}
