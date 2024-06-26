// Mocks generated by Mockito 5.4.4 from annotations
// in autonomy_flutter/test/generate_mock/service/mock_chat_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:autonomy_flutter/gateway/chat_api.dart' as _i6;
import 'package:autonomy_flutter/model/pair.dart' as _i4;
import 'package:autonomy_flutter/service/chat_service.dart' as _i2;
import 'package:libauk_dart/libauk_dart.dart' as _i5;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [ChatService].
///
/// See the documentation for Mockito's code generation for more information.
class MockChatService extends _i1.Mock implements _i2.ChatService {
  MockChatService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<void> connect({
    required String? address,
    required String? id,
    required _i4.Pair<_i5.WalletStorage, int>? wallet,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #connect,
          [],
          {
            #address: address,
            #id: id,
            #wallet: wallet,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  void addListener(_i2.ChatListener? listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i3.Future<void> removeListener(_i2.ChatListener? listener) =>
      (super.noSuchMethod(
        Invocation.method(
          #removeListener,
          [listener],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  void sendMessage(
    dynamic message, {
    String? listenerId,
    String? requestId,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #sendMessage,
          [message],
          {
            #listenerId: listenerId,
            #requestId: requestId,
          },
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i3.Future<void> dispose() => (super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  bool isConnecting({
    required String? address,
    required String? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #isConnecting,
          [],
          {
            #address: address,
            #id: id,
          },
        ),
        returnValue: false,
      ) as bool);
  @override
  _i3.Future<void> reconnect() => (super.noSuchMethod(
        Invocation.method(
          #reconnect,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> sendPostcardCompleteMessage(
    String? address,
    String? id,
    _i4.Pair<_i5.WalletStorage, int>? wallet,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendPostcardCompleteMessage,
          [
            address,
            id,
            wallet,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<List<_i6.ChatAlias>> getAliases({
    required String? indexId,
    required _i4.Pair<_i5.WalletStorage, int>? wallet,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAliases,
          [],
          {
            #indexId: indexId,
            #wallet: wallet,
          },
        ),
        returnValue: _i3.Future<List<_i6.ChatAlias>>.value(<_i6.ChatAlias>[]),
      ) as _i3.Future<List<_i6.ChatAlias>>);
  @override
  _i3.Future<bool> setAlias({
    required String? alias,
    required String? indexId,
    required _i4.Pair<_i5.WalletStorage, int>? wallet,
    required String? address,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlias,
          [],
          {
            #alias: alias,
            #indexId: indexId,
            #wallet: wallet,
            #address: address,
          },
        ),
        returnValue: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);
}
