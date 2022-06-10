/* SPDX-License-Identifier: BSD-2-Clause-Patent
 * Copyright © 2022 Bitmark. All rights reserved.
 * Use of this source code is governed by the BSD-2-Clause Plus Patent License
 * that can be found in the LICENSE file.
 */

import android.net.Uri
import androidx.annotation.NonNull
import com.bitmark.autonomy_flutter.jsonKT
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.github.novacrypto.base58.Base58
import it.airgap.beaconsdk.blockchain.substrate.substrate
import it.airgap.beaconsdk.blockchain.tezos.data.TezosAccount
import it.airgap.beaconsdk.blockchain.tezos.data.TezosAppMetadata
import it.airgap.beaconsdk.blockchain.tezos.data.TezosNetwork
import it.airgap.beaconsdk.blockchain.tezos.data.TezosPermission
import it.airgap.beaconsdk.blockchain.tezos.data.operation.*
import it.airgap.beaconsdk.blockchain.tezos.internal.wallet.TezosWallet
import it.airgap.beaconsdk.blockchain.tezos.message.request.BroadcastTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.OperationTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.PermissionTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.SignPayloadTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.response.OperationTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.PermissionTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.SignPayloadTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.tezos
import it.airgap.beaconsdk.client.wallet.BeaconWalletClient
import it.airgap.beaconsdk.core.data.*
import it.airgap.beaconsdk.core.internal.data.HexString
import it.airgap.beaconsdk.core.internal.utils.*
import it.airgap.beaconsdk.core.message.*
import it.airgap.beaconsdk.transport.p2p.matrix.p2pMatrix
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.*
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap

class TezosBeaconDartPlugin : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel

    fun createChannels(@NonNull flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tezos_beacon")
        channel.setMethodCallHandler(this)
        eventChannel =
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, "tezos_beacon/event")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "connect" -> {
                startBeacon()
            }
            "getConnectionURI" ->
                getConnectionURI(call, result)
            "getPostMessageConnectionURI" ->
                getPostMessageConnectionURI(call, result)
            "handlePostMessageOpenChannel" ->
                handlePostMessageOpenChannel(call, result)
            "handlePostMessageMessage" ->
                handlePostMessageMessage(call, result)
            "addPeer" -> {
                val link: String = call.argument("link") ?: ""
                addPeer(link, result)
            }
            "removePeer" ->
                removePeers()
            "response" ->
                respond(call, result)
            "pause", "resume" -> result.success("")
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        CoroutineScope(Dispatchers.IO).launch {
            requestPublisher
                .onEach { }
                .collect { request ->
                    val rev: HashMap<String, Any> = HashMap()
                    val params: HashMap<String, Any> = HashMap()
                    params["id"] = request.id
                    params["blockchainIdentifier"] = request.blockchainIdentifier
                    params["senderID"] = request.senderId
                    params["version"] = request.version
                    params["originID"] = request.origin.id

                    when (request) {
                        is PermissionTezosRequest -> {
                            val permissionRequest: PermissionTezosRequest = request

                            params["type"] = "permission"
                            permissionRequest.appMetadata.icon?.let {
                                params["icon"] = it
                            }
                            params["appName"] = permissionRequest.appMetadata.name
                        }
                        is SignPayloadTezosRequest -> {
                            val signPayload: SignPayloadTezosRequest = request

                            params["type"] = "signPayload"
                            signPayload.appMetadata?.icon?.let {
                                params["icon"] = it
                            }
                            params["appName"] = signPayload.appMetadata?.name ?: ""
                            params["payload"] = signPayload.payload
                            params["sourceAddress"] = signPayload.sourceAddress
                        }
                        is OperationTezosRequest -> {
                            val operationRequest: OperationTezosRequest = request

                            params["type"] = "operation"
                            operationRequest.appMetadata?.icon?.let {
                                params["icon"] = it
                            }
                            params["appName"] = operationRequest.appMetadata?.name ?: ""
                            params["sourceAddress"] = operationRequest.sourceAddress

                            fun getParams(value: MichelineMichelsonV1Expression): Any {
                                val result: HashMap<String, Any> = HashMap()

                                when (value) {
                                    is MichelinePrimitiveApplication -> {
                                        result["prim"] = value.prim
                                        value.args?.map { arg -> getParams(arg) }?.let {
                                            result["args"] = it
                                        }
                                        value.annots?.let {
                                            result["annots"] = it
                                        }
                                    }
                                    is MichelinePrimitiveInt -> {
                                        result["int"] = value.int
                                    }
                                    is MichelinePrimitiveString -> {
                                        result["string"] = value.string
                                    }
                                    is MichelinePrimitiveBytes -> {
                                        result["bytes"] = HexString(value.bytes).asString(withPrefix = false)
                                    }
                                    is MichelineNode -> {
                                        return value.expressions.map { arg -> getParams(arg) }
                                    }
                                }

                                return result
                            }

                            val operationDetails: ArrayList<HashMap<String, Any>> = ArrayList()
                            operationRequest.operationDetails.forEach { operation ->
                                if (operation.kind == TezosOperation.Kind.Origination) {
                                    (operation as? TezosOriginationOperation)?.let { origination ->
                                        val detail: HashMap<String, Any> = HashMap()
                                        detail["kind"] = "origination"
                                        origination.source?.let {
                                            detail["source"] = it
                                        }
                                        origination.gasLimit?.let {
                                            detail["gasLimit"] = it
                                        }
                                        origination.storageLimit?.let {
                                            detail["storageLimit"] = it
                                        }
                                        origination.fee?.let {
                                            detail["fee"] = it
                                        }
                                        origination.balance.let {
                                            detail["amount"] = it
                                        }
                                        origination.counter?.let {
                                            detail["counter"] = it
                                        }
                                        detail["code"] = getParams(origination.script.code)
                                        detail["storage"] = getParams(origination.script.storage)

                                        operationDetails.add(detail)
                                    }
                                } else {
                                    (operation as? TezosTransactionOperation)?.let { transaction ->
                                        val detail: HashMap<String, Any> = HashMap()
                                        detail["kind"] = "transaction"
                                        transaction.destination.let {
                                            detail["destination"] = it
                                        }
                                        transaction.source?.let {
                                            detail["source"] = it
                                        }
                                        transaction.gasLimit?.let {
                                            detail["gasLimit"] = it
                                        }
                                        transaction.storageLimit?.let {
                                            detail["storageLimit"] = it
                                        }
                                        transaction.fee?.let {
                                            detail["fee"] = it
                                        }
                                        transaction.amount.let {
                                            detail["amount"] = it
                                        }
                                        transaction.counter?.let {
                                            detail["counter"] = it
                                        }
                                        transaction.parameters?.entrypoint?.let {
                                            detail["entrypoint"] = it
                                        }
                                        transaction.parameters?.value?.let { value -> getParams(value) }
                                            ?.let {
                                                detail["parameters"] = it
                                            }

                                        operationDetails.add(detail)
                                    }
                                }
                            }

                            params["operationDetails"] = operationDetails
                        }
                        else -> {
                        }
                    }

                    rev["eventName"] = "observeRequest"
                    rev["params"] = params

                    withContext(Dispatchers.Main) {
                        events?.success(rev)
                    }
                }
        }

        CoroutineScope(Dispatchers.IO).launch {
            dappPermissionPublisher
                .collect {
                    val rev: HashMap<String, Any> = HashMap()
                    val params: HashMap<String, Any> = HashMap()

                    dependencyRegistry.crypto

                    params["type"] = "beaconRequestedPermission"
                    val data = jsonKT.encodeToString(it).encodeToByteArray()
                    params["peer"] = data

                    rev["eventName"] = "observeEvent"
                    rev["params"] = params

                    withContext(Dispatchers.Main) {
                        events?.success(rev)
                    }
                }
        }

        CoroutineScope(Dispatchers.IO).launch {
            eventPublisher
                .collect {
                    val rev: HashMap<String, Any> = HashMap()
                    val params: HashMap<String, Any> = HashMap()

                    params["type"] = "beaconLinked"
                    val data =
                        jsonKT.encodeToString(it).encodeToByteArray()
                    params["connection"] = data

                    rev["eventName"] = "observeEvent"
                    rev["params"] = params

                    withContext(Dispatchers.Main) {
                        events?.success(rev)
                    }
                }
        }


    }

    override fun onCancel(arguments: Any?) {
    }

    private var beaconClient: BeaconWalletClient? = null

    private var awaitingRequest: BeaconRequest? = null
    private var requestPublisher = MutableSharedFlow<BeaconRequest>()
    private var eventPublisher = MutableSharedFlow<TezosWalletConnection>()
    private var dappPermissionPublisher = MutableSharedFlow<P2pPeer>()

    private fun startBeacon() {
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient = BeaconWalletClient(
                "Autonomy",
            ) {
                support(tezos(), substrate())
                use(p2pMatrix())

                ignoreUnsupportedBlockchains = true
            }

            launch {
                beaconClient?.connect()
                    ?.onEach { result -> result.getOrNull()?.let { saveAwaitingRequest(it) } }
                    ?.collect { result ->
                        result.getOrNull()?.let {
                            when (it) {
                                is PermissionTezosResponse -> {
                                    val peerPublicKey = it.requestOrigin.id

                                    val peer =
                                        dependencyRegistry.storageManager.findPeer { peer -> peer.publicKey == peerPublicKey }

                                    eventPublisher.emit(
                                        TezosWalletConnection(
                                            it.account.address,
                                            peer,
                                            it
                                        )
                                    )
                                }
                                is BeaconRequest -> {
                                    requestPublisher.emit(it)
                                }
                                else -> {
                                    //ignore
                                }
                            }
                        }
                    }
            }

            startOpenChannelListener()
        }
    }

    private fun getConnectionURI(call: MethodCall, result: Result) {
        val rev: HashMap<String, Any> = HashMap()
        rev["error"] = 0

        beaconClient?.let { client ->
            val relayServers = client.connectionController.getRelayServers()
            val peer = P2pPeer(
                id = UUID.randomUUID().toString().lowercase(),
                name = beaconSdk.app.name,
                publicKey = beaconSdk.beaconId,
                relayServer = relayServers.firstOrNull() ?: "beacon-node-1.sky.papers.tech",
                version = "2"
            )

            dependencyRegistry.serializer.serialize(peer).getOrNull()?.let {
                rev["uri"] = "?type=tzip10&data=$it"
            } ?: run {
                rev["uri"] = ""
            }
        } ?: run {
            rev["uri"] = ""
        }

        result.success(rev)
    }

    private fun getPostMessageConnectionURI(call: MethodCall, result: Result) {
        val rev: HashMap<String, Any> = HashMap()
        rev["error"] = 0

        val peer = PostMessagePairingRequest(
            id = UUID.randomUUID().toString().lowercase(),
            name = beaconSdk.app.name,
            icon = null,
            appUrl = null,
            publicKey = beaconSdk.beaconId,
            type = "postmessage-pairing-request"
        )

        val json = jsonKT.encodeToString(peer)
        val encodedData =
            dependencyRegistry.base58Check.encode(json.toByteArray(Charsets.UTF_8)).getOrNull()
                ?: ""
        rev["uri"] = encodedData

        result.success(rev)
    }

    private fun handlePostMessageOpenChannel(call: MethodCall, result: Result) {
        val client = beaconClient ?: return

        val payload: String = call.argument("payload") ?: ""
        val decryptedResult = dependencyRegistry.crypto.decryptMessageWithKeyPair(
            payload.asHexString().toByteArray(),
            beaconSdk.app.keyPair.publicKey,
            beaconSdk.app.keyPair.privateKey
        )

        decryptedResult.getOrNull()?.let {
            val pairingResponse =
                jsonKT.decodeFromString<ExtendedPostMessagePairingResponse>(it.toString(Charsets.UTF_8))
            val extensionPublicKey = pairingResponse.publicKey.asHexString().toByteArray()
            val pairingPeer = pairingResponse.extractPeer()

            val metadata = client.getOwnAppMetadata()
            val request = PostMessagePermissionRequest(
                id = UUID.randomUUID().toString().lowercase(),
                version = "2",
                blockchainIdentifier = "tezos",
                appMetadata = metadata,
                network = TezosNetwork.Mainnet(),
                scopes = listOf(
                    TezosPermission.Scope.OperationRequest,
                    TezosPermission.Scope.Sign
                ),
                senderID = metadata.senderId,
                type = "permission_request"
            )

            val json = jsonKT.encodeToString(request)

            val message =
                dependencyRegistry.base58Check.encode(json.toByteArray(Charsets.UTF_8)).getOrNull()
                    ?: return

            val sharedKey = dependencyRegistry.crypto.createClientSessionKeyPair(
                extensionPublicKey,
                beaconSdk.app.keyPair.privateKey
            ).getOrNull() ?: return

            val encryptedResult =
                dependencyRegistry.crypto.encryptMessageWithSharedKey(message, sharedKey.tx)
            val encryptedData = encryptedResult.getOrNull()?.toHexString()?.asString() ?: return

            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["peer"] = jsonKT.encodeToString(pairingPeer)
            rev["permissionRequestMessage"] = encryptedData

            result.success(rev)
        }
    }

    private fun handlePostMessageMessage(call: MethodCall, result: Result) {
        val extensionPublicKey: String = call.argument("extensionPublicKey") ?: ""
        val payload: String = call.argument("payload") ?: ""

        val sharedKey = dependencyRegistry.crypto.createServerSessionKeyPair(
            extensionPublicKey.asHexString().toByteArray(),
            beaconSdk.app.keyPair.privateKey
        ).getOrNull() ?: return

        val decryptedResult = dependencyRegistry.crypto.decryptMessageWithSharedKey(
            payload.asHexString(),
            sharedKey.rx
        )

        decryptedResult.getOrNull()?.let {
            val decodedMessage =
                dependencyRegistry.base58Check.decode(it.toString(Charsets.UTF_8)).getOrNull()
                    ?: return

            try {
                val postMessageResponse = jsonKT.decodeFromString(
                    PostMessageResponse.serializer(),
                    decodedMessage.toString(Charsets.UTF_8)
                )

                val permissionTezosResponse = postMessageResponse.convertToPermissionResponse()

                val tzAddress = permissionTezosResponse.account.address

                val rev: HashMap<String, Any> = HashMap()
                rev["error"] = 0
                rev["tzAddress"] = tzAddress
                rev["response"] = jsonKT.encodeToString(permissionTezosResponse)

                result.success(rev)
            } catch (e: SerializationException) {
                val rev: HashMap<String, Any> = HashMap()
                rev["error"] = 1

                try {
                    val errorResponse = jsonKT.decodeFromString(
                        PostMessageErrorResponse.serializer(),
                        decodedMessage.toString(Charsets.UTF_8)
                    )
                    if (errorResponse.errorType == "ABORTED_ERROR") {
                        rev["reason"] = "aborted"
                    } else {
                        rev["reason"] = "incorrectData"
                    }
                } catch (e: SerializationException) {
                    rev["reason"] = "incorrectData"
                }

                result.success(rev)
            }
        }
    }

    private fun respond(call: MethodCall, result: Result) {
        val id: String? = call.argument("id")
        val request = awaitingRequest ?: return

        if (request.id != id) return

        CoroutineScope(Dispatchers.IO).launch {
            val response = when (request) {
                is PermissionTezosRequest -> {
                    val publicKey: String? = call.argument("publicKey")

                    publicKey?.let {
                        val tzAddress = TezosWallet(
                            dependencyRegistry.crypto,
                            dependencyRegistry.base58Check
                        ).address(it).getOrDefault("")

                        PermissionTezosResponse.from(
                            request,
                            TezosAccount(
                                publicKey = it,
                                address = tzAddress,
                                network = TezosNetwork.Mainnet(),
                            ),
                            listOf(
                                TezosPermission.Scope.Sign,
                                TezosPermission.Scope.OperationRequest
                            )
                        )
                    } ?: ErrorBeaconResponse.from(request, BeaconError.Aborted)
                }
                is OperationTezosRequest -> {
                    val txHash: String? = call.argument("txHash")

                    txHash?.let {
                        OperationTezosResponse.from(request, txHash)
                    } ?: ErrorBeaconResponse.from(request, BeaconError.Aborted)
                }
                is SignPayloadTezosRequest -> {
                    val signature: String? = call.argument("signature")

                    signature?.let {
                        SignPayloadTezosResponse.from(request, SigningType.Raw, it)
                    } ?: ErrorBeaconResponse.from(request, BeaconError.Aborted)
                }
                is BroadcastTezosRequest -> ErrorBeaconResponse(
                    request.id,
                    request.version,
                    request.origin,
                    BeaconError.Unknown,
                    null
                )
                else -> ErrorBeaconResponse.from(request, BeaconError.Unknown)
            }
            beaconClient?.respond(response)
            removeAwaitingRequest()
            result.success(mapOf("error" to 0))
        }
    }

    private fun addPeer(link: String, result: Result) {
        val peer = extractPeer(link)
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.addPeers(peer)
            val jsonPeer = jsonKT.encodeToString(peer)
            result.success(mapOf("error" to 0, "result" to jsonPeer))
        }
    }

    private fun removePeers() {
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.removeAllPeers()
        }
    }

    private fun saveAwaitingRequest(message: BeaconMessage) {
        awaitingRequest = if (message is BeaconRequest) message else null
    }

    private fun removeAwaitingRequest() {
        awaitingRequest = null
    }

    private fun extractPeer(link: String): P2pPeer {
        val uri = Uri.parse(link)
        val message = uri.getQueryParameter("data")
        val messageData = Base58.base58Decode(message)

        val json = messageData.toString(Charsets.UTF_8).substringAfter("{").substringBeforeLast("}")

        return jsonKT.decodeFromString("{$json}")
    }

    private suspend fun startOpenChannelListener() {
        beaconClient?.let { client ->
            client.connectionController.startOpenChannelListener()
                .collect {
                    val peer = it.getOrNull() ?: return@collect

                    val metadata = client.getOwnAppMetadata()
                    val request = PermissionTezosRequest(
                        id = UUID.randomUUID().toString().lowercase(),
                        version = "2",
                        blockchainIdentifier = "tezos",
                        senderId = metadata.senderId,
                        appMetadata = TezosAppMetadata(
                            metadata.senderId,
                            metadata.name,
                            metadata.icon
                        ),
                        origin = Origin.forPeer(peer = peer),
                        network = TezosNetwork.Mainnet(),
                        scopes = listOf(
                            TezosPermission.Scope.OperationRequest,
                            TezosPermission.Scope.Sign
                        )
                    )

                    client.request(request)

                    dappPermissionPublisher.emit(peer)
                }
        }
    }
}

@Serializable
data class TezosWalletConnection(
    @SerialName("address")
    val address: String,
    @SerialName("peer")
    val peer: Peer?,
    @SerialName("permissionResponse")
    val permissionResponse: PermissionTezosResponse
)


@Serializable
data class PostMessagePairingRequest(
    @SerialName("id")
    val id: String,
    @SerialName("name")
    val name: String,
    @SerialName("icon")
    val icon: String?,
    @SerialName("appUrl")
    val appUrl: String?,
    @SerialName("publicKey")
    val publicKey: String,
    @SerialName("type")
    val type: String
)

@Serializable
data class ExtendedPostMessagePairingResponse(
    @SerialName("id")
    val id: String,
    @SerialName("type")
    val type: String,
    @SerialName("name")
    val name: String,
    @SerialName("publicKey")
    val publicKey: String,
    @SerialName("icon")
    val icon: String?,
    @SerialName("appUrl")
    val appUrl: String?,
    @SerialName("senderId")
    val senderId: String,
) {
    fun extractPeer(): P2pPeer { // should be postMessagePeer; but we use that just for field values
        return P2pPeer(
            id = id,
            name = name,
            publicKey = publicKey,
            relayServer = "",
            version = "",
            icon = icon,
            appUrl = appUrl
        )
    }
}

@Serializable
data class PostMessagePermissionRequest(
    @SerialName("type")
    val type: String,
    @SerialName("id")
    val id: String,
    @SerialName("blockchainIdentifier")
    val blockchainIdentifier: String,
    @SerialName("senderID")
    val senderID: String,
    @SerialName("appMetadata")
    val appMetadata: AppMetadata,
    @SerialName("network")
    val network: Network,
    @SerialName("scopes")
    val scopes: List<TezosPermission.Scope>,
    @SerialName("version")
    val version: String
)

@Serializable
data class PostMessageResponse(
    @SerialName("id")
    val id: String,
    @SerialName("publicKey")
    val publicKey: String,
    @SerialName("network")
    val network: TezosNetwork,
    @SerialName("scopes")
    val scopes: List<TezosPermission.Scope>,
    @SerialName("version")
    val version: String,
    @SerialName("senderId")
    val senderId: String,
    @SerialName("type")
    val type: String
) {
    fun convertToPermissionResponse(): PermissionTezosResponse {
        val request = PermissionTezosRequest(
            id = id,
            blockchainIdentifier = "tezos",
            network = network,
            scopes = scopes,
            version = version,
            appMetadata = TezosAppMetadata(senderId, ""),
            origin = Origin.P2P(senderId),
            senderId = senderId
        )
        val tzAddress = TezosWallet(
            dependencyRegistry.crypto,
            dependencyRegistry.base58Check
        ).address(publicKey).getOrDefault("")

        return PermissionTezosResponse.from(
            request,
            TezosAccount(
                publicKey = publicKey,
                address = tzAddress,
                network = network
            ),
            scopes
        )
    }
}

@Serializable
data class PostMessageErrorResponse(
    @SerialName("id")
    val id: String,
    @SerialName("version")
    val version: String,
    @SerialName("senderId")
    val senderId: String,
    @SerialName("type")
    val type: String,
    @SerialName("errorType")
    val errorType: String
)