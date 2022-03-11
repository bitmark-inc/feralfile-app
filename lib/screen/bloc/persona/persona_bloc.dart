import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

part 'persona_state.dart';

class PersonaBloc extends Bloc<PersonaEvent, PersonaState> {
  CloudDatabase _cloudDB;
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;

  PersonaBloc(
      this._cloudDB, this._walletConnectService, this._tezosBeaconService)
      : super(PersonaState()) {
    on<CreatePersonaEvent>((event, emit) async {
      emit(PersonaState(createAccountState: ActionState.loading));
      // await Future.delayed(SHOW_DIALOG_DURATION);

      final uuid = Uuid().v4();
      final walletStorage = LibAukDart.getWallet(uuid);
      await walletStorage.createKey("");

      final persona = Persona.newPersona(uuid: uuid, name: "");
      await _cloudDB.personaDao.insertPersona(persona);

      emit(
          PersonaState(createAccountState: ActionState.done, persona: persona));

      await Future.delayed(Duration(microseconds: 500), () {
        emit(state.copyWith(createAccountState: ActionState.notRequested));
      });
    });

    on<GetListPersonaEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      List<Persona> _namedPersonas = [];

      for (var persona in personas) {
        if (persona.name.isEmpty) {
          final address = await persona.wallet().getETHAddress();
          _namedPersonas.add(persona.copyWith(name: address.mask(4)));
        } else {
          _namedPersonas.add(persona);
        }
      }

      _namedPersonas.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(state.copyWith(personas: _namedPersonas));
    });

    on<GetInfoPersonaEvent>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.uuid);
      emit(state.copyWith(persona: persona));
    });

    on<NamePersonaEvent>((event, emit) async {
      final oldPersona = state.persona;
      if (oldPersona == null) return;
      emit(state.copyWith(namePersonaState: ActionState.loading));

      await oldPersona.wallet().updateName(event.name);
      final updatedPersona = oldPersona.copyWith(name: event.name);
      await _cloudDB.personaDao.updatePersona(updatedPersona);

      emit(state.copyWith(
          namePersonaState: ActionState.done, persona: updatedPersona));
    });

    on<ImportPersonaEvent>((event, emit) async {
      log.info('[PersonaBloc] ImportPersonaEvent');
      try {
        emit(state.copyWith(importPersonaState: ActionState.loading));
        // await Future.delayed(SHOW_DIALOG_DURATION);

        final uuid = Uuid().v4();
        final walletStorage = LibAukDart.getWallet(uuid);
        await walletStorage.importKey(
            event.words, "", DateTime.now().microsecondsSinceEpoch);

        final persona = Persona.newPersona(uuid: uuid, name: "");
        await _cloudDB.personaDao.insertPersona(persona);

        emit(state.copyWith(
            importPersonaState: ActionState.done, persona: persona));
      } catch (exception) {
        emit(state.copyWith(importPersonaState: ActionState.error));
      }
    });

    on<DeletePersonaEvent>((event, emit) async {
      log.info('[PersonaBloc] DeletePersonaEvent');
      emit(state.copyWith(deletePersonaState: ActionState.loading));

      final deletedPersona = event.persona;
      await _cloudDB.personaDao.deletePersona(deletedPersona);
      await LibAukDart.getWallet(deletedPersona.uuid).removeKeys();

      final connections = await _cloudDB.connectionDao.getConnections();
      Set<WCPeerMeta> wcPeers = {};
      Set<P2PPeer> bcPeers = {};

      for (var connection in connections) {
        switch (connection.connectionType) {
          case 'dappConnect':
            if (deletedPersona.uuid == connection.wcConnection?.personaUuid) {
              await _cloudDB.connectionDao.deleteConnection(connection);

              final wcPeer = connection.wcConnection?.sessionStore.peerMeta;
              if (wcPeer != null) wcPeers.add(wcPeer);
            }
            break;

          case 'beaconP2PPeer':
            if (deletedPersona.uuid ==
                connection.beaconConnectConnection?.personaUuid) {
              await _cloudDB.connectionDao.deleteConnection(connection);

              final bcPeer = connection.beaconConnectConnection?.peer;
              if (bcPeer != null) bcPeers.add(bcPeer);
            }
            break;

          // Note: Should app delete feralFileWeb3 too ??
        }
      }

      try {
        for (var peer in wcPeers) {
          await _walletConnectService.disconnect(peer);
        }

        for (var peer in bcPeers) {
          await _tezosBeaconService.removePeer(peer);
        }
      } catch (exception) {
        Sentry.captureException(exception);
      }

      emit(state.copyWith(deletePersonaState: ActionState.done));
    });
  }
}
