//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class BackupVersions {
  BackupVersions({
    required this.versions,
  });

  List<dynamic> versions;

  factory BackupVersions.fromJson(Map<String, dynamic> json) => BackupVersions(
        versions: json["result"] as List<dynamic>,
      );

  Map<String, dynamic> toJson() => {"result": versions};
}
