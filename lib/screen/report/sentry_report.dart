//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:path/path.dart';
import 'package:sentry/sentry_io.dart';

Future<String> reportSentry(Map payload) async {
  SentryId sentryId;
  if (payload["exception"] != null) {
    sentryId = await Sentry.captureException(
      payload["exception"],
      stackTrace: payload["stackTrace"],
      withScope: _addAttachment,
    );
  } else {
    final deviceID = await getDeviceID();
    sentryId =
        await Sentry.captureMessage(deviceID ?? "", withScope: _addAttachment);
  }

  /*
  Don't send userFeedback anymore
  final feedback = SentryUserFeedback(
    eventId: sentryId,
    comments: comments,
  );

  Sentry.captureUserFeedback(feedback);
  */

  return sentryId.toString();
}

Future _addAttachment(Scope scope) async {
  final logFilePath = (await getLogFile()).path;
  final attachment =
      IoSentryAttachment.fromPath(logFilePath, filename: basename(logFilePath));

  scope.addAttachment(attachment);
}
