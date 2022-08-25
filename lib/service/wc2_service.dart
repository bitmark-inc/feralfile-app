//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/wc2_channel.dart';

class Wc2Service extends Wc2Handler {
  final NavigationService _navigationService;

  late Wc2Channel _wc2channel;

  Wc2Service(this._navigationService) {
    _wc2channel = Wc2Channel(handler: this);
  }

  Future connect(String uri) async {
    await _wc2channel.pairClient(uri);
  }

  Future approveSession(String id) async {
    await _wc2channel.approve(
        id, "zQ3shrMBDvnTFPY2CXUuJQo6jUQMJHxXjirgZdSQnTFtsGVqs");
  }

  Future rejectSession(String id) async {
    await _wc2channel.reject(id);
  }

  Future respondOnApprove(String topic, String response) async {
    await _wc2channel.respondOnApprove(topic, response);
  }

  Future respondOnReject(String topic) async {
    await _wc2channel.respondOnReject(topic);
  }

  @override
  void onSessionProposal(Wc2Proposal proposal) {
    _navigationService.navigateTo(AppRouter.wc2ConnectPage,
        arguments: proposal);
  }

  @override
  void onSessionRequest(Wc2Request request) {
    _navigationService.navigateTo(AppRouter.wc2PermissionPage,
        arguments: request);
  }
}
