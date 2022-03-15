import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.github.novacrypto.base58.Base58
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
import it.airgap.beaconsdk.core.internal.utils.*
import it.airgap.beaconsdk.core.message.*
import it.airgap.beaconsdk.transport.p2p.matrix.p2pMatrix
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
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
                addPeer(link)
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

                            fun getParams(value: MichelineMichelsonV1Expression): Map<String, Any> {
                                val result: HashMap<String, Any> = HashMap()

                                when (value) {
                                    is MichelinePrimitiveApplication -> {
                                        result["prim"] = value.prim
                                        value.args?.map { arg -> getParams(arg) }?.let {
                                            result["args"] = it
                                        }
                                    }
                                    is MichelinePrimitiveInt -> {
                                        result["int"] = value.int
                                    }
                                    is MichelinePrimitiveString -> {
                                        result["string"] = value.string
                                    }
                                    is MichelinePrimitiveBytes -> {
                                        result["bytes"] = value.bytes
                                    }
                                    is MichelineNode -> {
                                        result["expressions"] =
                                            value.expressions.map { arg -> getParams(arg) }
                                    }
                                }

                                return result
                            }

                            val operationDetails: ArrayList<HashMap<String, Any>> = ArrayList()
                            operationRequest.operationDetails.forEach { operation ->
                                (operation as? TezosTransactionOperation)?.let { transaction ->
                                    val detail: HashMap<String, Any> = HashMap()
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
                    val data = jsonKT.encodeToString(it, P2pPeer::class).encodeToByteArray()
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
                        jsonKT.encodeToString(it, TezosWalletConnection::class).encodeToByteArray()
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
                listOf(
                    tezos(),
                ),
            ) {
                addConnections(
                    P2P(p2pMatrix()),
                )
            }

            launch {
                beaconClient?.connect()
                    ?.onEach { result -> result.getOrNull()?.let { saveAwaitingRequest(it) } }
                    ?.collect { result ->
                        result.getOrNull()?.let {
                            when (it) {
                                is PermissionTezosResponse -> {
                                    val publicKey = it.publicKey
                                    val peerPublicKey = it.requestOrigin.id

                                    val peer =
                                        dependencyRegistry.storageManager.findPeer { peer -> peer.publicKey == peerPublicKey }
                                    val address = TezosWallet(
                                        dependencyRegistry.crypto,
                                        dependencyRegistry.base58Check
                                    ).address(publicKey).getOrDefault("")

                                    eventPublisher.emit(TezosWalletConnection(address, peer, it))
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

        val json = jsonKT.encodeToString(PostMessagePairingRequest.serializer(), peer)
        val encodedData = dependencyRegistry.base58Check.encode(json.toByteArray(Charsets.UTF_8)).getOrNull() ?: ""
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

            val json = jsonKT.encodeToString(PostMessagePermissionRequest.serializer(), request)
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
            rev["peer"] = jsonKT.encodeToString(P2pPeer.serializer(), pairingPeer)
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

                val tzAddress = TezosWallet(
                    dependencyRegistry.crypto,
                    dependencyRegistry.base58Check
                ).address(permissionTezosResponse.publicKey).getOrDefault("")

                val rev: HashMap<String, Any> = HashMap()
                rev["error"] = 0
                rev["tzAddress"] = tzAddress
                rev["response"] = jsonKT.encodeToString(PermissionTezosResponse.serializer(), permissionTezosResponse)

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
                        PermissionTezosResponse.from(request, it)
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
        }
    }

    private fun addPeer(link: String) {
        val peer = extractPeer(link)
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.addPeers(peer)
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

    private val jsonKT = Json { ignoreUnknownKeys = true }

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
    val address: String,
    val peer: Peer?,
    val permissionResponse: PermissionTezosResponse
)


@Serializable
data class PostMessagePairingRequest(
    val id: String,
    val name: String,
    val icon: String?,
    val appUrl: String?,
    val publicKey: String,
    val type: String
)

@Serializable
data class ExtendedPostMessagePairingResponse(
    val id: String,
    val type: String,
    val name: String,
    val publicKey: String,
    val icon: String?,
    val appUrl: String?,
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
    val type: String,
    val id: String,
    val blockchainIdentifier: String,
    val senderID: String,
    val appMetadata: AppMetadata,
    val network: Network,
    val scopes: List<TezosPermission.Scope>,
    val version: String
)

@Serializable
data class PostMessageResponse(
    val id: String,
    val publicKey: String,
    val network: TezosNetwork,
    val scopes: List<TezosPermission.Scope>,
    val version: String,
    val senderId: String,
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
        return PermissionTezosResponse.from(
            request, publicKey, network, scopes
        )
    }
}

@Serializable
data class PostMessageErrorResponse(
    val id: String,
    val version: String,
    val senderId: String,
    val type: String,
    val errorType : String
)