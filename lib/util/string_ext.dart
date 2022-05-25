//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }

  String mask(int number) {
    return "[${this.substring(0, number)}...${this.substring(this.length - number, this.length)}]";
  }

  String maskIfNeeded() {
    if (this.contains(' ')) return this;
    return (this.length >= 36) ? this.mask(4) : this;
  }

  String? toIdentityOrMask(Map<String, String>? identityMap) {
    if (this.isEmpty) return null;
    final identity = identityMap?[this];
    return (identity != null && identity.isNotEmpty)
        ? identity
        : this.maskIfNeeded();
  }
}
