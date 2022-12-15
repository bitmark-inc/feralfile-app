//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'identity_bloc.dart';

abstract class IdentityEvent {}

/// Fetch for identities and emit events after getting from database and API
class GetIdentityEvent extends IdentityEvent {
  final Iterable<String> addresses;

  GetIdentityEvent(this.addresses);
}

/// Fetch for identities and do not emit events
class FetchIdentityEvent extends IdentityEvent {
  final Iterable<String> addresses;

  FetchIdentityEvent(this.addresses);
}

/// Remove all identities from app data
class RemoveAllEvent extends IdentityEvent {
  RemoveAllEvent();
}

class IdentityState {
  Map<String, String> identityMap;

  IdentityState(this.identityMap);
}
