// Mocks generated by Mockito 5.4.4 from annotations
// in autonomy_flutter/test/generate_mock/service/mock_tokens_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:nft_collection/models/asset_token.dart' as _i4;
import 'package:nft_collection/models/pending_tx_params.dart' as _i5;
import 'package:nft_collection/services/tokens_service.dart' as _i2;

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

/// A class which mocks [TokensService].
///
/// See the documentation for Mockito's code generation for more information.
class MockTokensService extends _i1.Mock implements _i2.TokensService {
  MockTokensService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isRefreshAllTokensListen => (super.noSuchMethod(
        Invocation.getter(#isRefreshAllTokensListen),
        returnValue: false,
      ) as bool);
  @override
  _i3.Future<dynamic> fetchTokensForAddresses(List<String>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchTokensForAddresses,
          [addresses],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
  @override
  _i3.Future<List<_i4.AssetToken>> fetchManualTokens(
          List<String>? indexerIds) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchManualTokens,
          [indexerIds],
        ),
        returnValue: _i3.Future<List<_i4.AssetToken>>.value(<_i4.AssetToken>[]),
      ) as _i3.Future<List<_i4.AssetToken>>);
  @override
  _i3.Future<dynamic> setCustomTokens(List<_i4.AssetToken>? assetTokens) =>
      (super.noSuchMethod(
        Invocation.method(
          #setCustomTokens,
          [assetTokens],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
  @override
  _i3.Future<_i3.Stream<List<_i4.AssetToken>>> refreshTokensInIsolate(
          Map<int, List<String>>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #refreshTokensInIsolate,
          [addresses],
        ),
        returnValue: _i3.Future<_i3.Stream<List<_i4.AssetToken>>>.value(
            _i3.Stream<List<_i4.AssetToken>>.empty()),
      ) as _i3.Future<_i3.Stream<List<_i4.AssetToken>>>);
  @override
  _i3.Future<dynamic> reindexAddresses(List<String>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #reindexAddresses,
          [addresses],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
  @override
  _i3.Future<dynamic> purgeCachedGallery() => (super.noSuchMethod(
        Invocation.method(
          #purgeCachedGallery,
          [],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
  @override
  _i3.Future<dynamic> postPendingToken(_i5.PendingTxParams? params) =>
      (super.noSuchMethod(
        Invocation.method(
          #postPendingToken,
          [params],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
}
