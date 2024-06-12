//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/canvas_channel_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';

class CanvasClientService {
  final CanvasChannelService _channelService;

  CanvasClientService(this._channelService);

  final NavigationService _navigationService = injector<NavigationService>();

  Offset currentCursorOffset = Offset.zero;

  CanvasControlClient _getStub(CanvasDevice device) =>
      _channelService.getStubV1(device);

  Future<void> sendKeyBoard(List<CanvasDevice> devices, int code) async {
    for (var device in devices) {
      final stub = _getStub(device);
      final sendKeyboardRequest = KeyboardEventRequest()..code = code;
      final response = await stub.keyboardEvent(sendKeyboardRequest);
      if (response.ok) {
        log.info('CanvasClientService: Keyboard Event Success $code');
      } else {
        log.info('CanvasClientService: Keyboard Event Failed $code');
      }
    }
  }

  // function to rotate canvas
  Future<void> rotateCanvas(CanvasDevice device,
      {bool clockwise = true}) async {
    final stub = _getStub(device);
    final rotateCanvasRequest = RotateRequest()..clockwise = clockwise;
    try {
      final response = await stub.rotate(rotateCanvasRequest);
      log.info('CanvasClientService: Rotate Canvas Success ${response.degree}');
    } catch (e) {
      log.info('CanvasClientService: Rotate Canvas Failed');
    }
  }

  Future<void> tap(List<CanvasDevice> devices) async {
    for (var device in devices) {
      final stub = _getStub(device);
      final tapRequest = TapGestureRequest();
      await stub.tapGesture(tapRequest);
    }
  }

  Future<void> drag(
      List<CanvasDevice> devices, Offset offset, Size touchpadSize) async {
    final dragRequest = DragGestureRequest()
      ..dx = offset.dx
      ..dy = offset.dy
      ..coefficientX = 1 / touchpadSize.width
      ..coefficientY = 1 / touchpadSize.height;
    currentCursorOffset += offset;
    for (var device in devices) {
      final stub = _getStub(device);
      await stub.dragGesture(dragRequest);
    }
  }

  Future<Offset> getCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.getCursorOffset(Empty());
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final dx = size.width * response.coefficientX * response.dx;
    final dy = size.height * response.coefficientY * response.dy;
    return Offset(dx, dy);
  }

  Future<void> setCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final dx = currentCursorOffset.dx / size.width;
    final dy = currentCursorOffset.dy / size.height;
    final request = CursorOffset()
      ..dx = dx
      ..dy = dy
      ..coefficientX = 1 / size.width
      ..coefficientY = 1 / size.height;

    await stub.setCursorOffset(request);
  }
}
