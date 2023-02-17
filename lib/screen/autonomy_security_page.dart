//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class AutonomySecurityPage extends StatelessWidget {
  const AutonomySecurityPage({Key? key}) : super(key: key);

  String get securityContent {
    if (Platform.isIOS) {
      return "security_content_ios".tr();
/*Autonomy secures your sensitive data, such as cryptographic seeds and private keys, on your closely held mobile device. It ensures your data's protection by following Apple's best security practices: Autonomy stores your keys in the iPhone Keychain, which encrypts them on disk using AES-256 (with the encryption key stored in your iPhone's Secure Enclave). They can only be retrieved through the Autonomy app “After First Unlock”. In order to access the Autonomy app, you must supply your personal identification, usually Face ID or Touch ID but possibly a PIN, depending on your iPhone model.

But, Autonomy wants your data to be not just secure, but also resilient. To make it much harder for you to lose your Autonomy keys, Autonomy utilizes the iCloud Keychain service, which synchronizes your Keychain content to your iCloud account, allowing access from your other devices logged into the iCloud. You must have "iCloud Backup" set to "On" and "Keychain" set to "On" in your iPhone Settings. You can even synchronize your keys to a new iPhone if you lose your current one. (Other data can also be backed up with an Autonomy subscription.)

Though your Keychain is synced to the iCloud, it is still accessible only to you, thanks to Apple's use of industry best-practice end-to-end encryption, again built on AES-256. Because your Keychain is encrypted before it reaches the cloud, no one else ever has access to it, not Apple and not Bitmark. If you ever want to sync it to a new device, that requires not just the authentication information for your iCloud account, but also knowledge of one of the PINs or passwords for one of your devices.

Of course all security ultimately rests on the code, and whether it makes the proper use of all of these best practices. We plan to open the Autonomy source code in the near future, so that you can check our work if you wish.
""";*/
    } else {
      return "security_content_else".tr();
/*Autonomy secures your sensitive data, such as cryptographic seeds and private keys, on your closely held mobile device. It ensures your data's protection by following Android’s best security practices: Autonomy stores your keys using the Android KeyStore system and the AES-256 cipher. This encrypts your keys on disk and protects them  from access by other applications. On applicable Android devices, they are also stored in a Secure Enclave, which has its own CPU and improves tamper resistance and secure storage. Your keys can only be retrieved through the Autonomy app; in order to access the Autonomy app, you must supply your personal identification, usually a thumb print or face recognition but possibly a PIN, depending on your Android model.

Autonomy wants your data to be not just secure, but also resilient. To make it much harder for you to lose your Autonomy keys, Autonomy has created a unique encrypted cloud backup system. By combining Android Security Crypto with the Block Store system, Autonomy encrypts your keys and stores them on the cloud, so that they can be restored even if you lose your Android device and install Autonomy on a new phone or tablet. (Other data can also be backed up with an Autonomy subscription.)

The cloud backup system uses end-to-end encryption where available: if you are using an older Android system (Android 8 or earlier) or you do not have screen lock enabled, you will be warned that end-to-end encryption is not in use. Because your keys are encrypted before they reach the cloud, no one else ever has access to them, not Google and not Bitmark.

Of course all security ultimately rests on the code, and whether it makes the proper use of all of these best practices. We plan to open the Autonomy source code in the near future, so that you can check our work if you wish.
""";*/
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "autonomy_security".tr(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageHorizontalEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Text(securityContent, style: theme.textTheme.ppMori400Black14),
            ],
          ),
        ),
      ),
    );
  }
}
