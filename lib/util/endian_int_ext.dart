//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

extension BigEndian on int {
  List<int> uint32BE() => [
        (this >> 24) & 0xff,
        (this >> 16) & 0xff,
        (this >> 8) & 0xff,
        this & 0xff
      ];

  List<int> uint32LE() => [
        this & 0xff,
        (this >> 8) & 0xff,
        (this >> 16) & 0xff,
        (this >> 24) & 0xff
      ];

  List<int> varint() {
    if (this < 0xfd) {
      return [this & 0xff];
    } else if (this <= 0xffff) {
      return [0xfd, this & 0xff, (this >> 8) & 0xff];
    } else {
      return [0xfe] + uint32LE();
    }
  }
}
