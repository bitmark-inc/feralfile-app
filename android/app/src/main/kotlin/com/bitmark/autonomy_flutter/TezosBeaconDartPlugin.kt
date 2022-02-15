import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.github.novacrypto.base58.Base58
import it.airgap.beaconsdk.blockchain.tezos.data.TezosError
import it.airgap.beaconsdk.blockchain.tezos.data.operation.*
import it.airgap.beaconsdk.blockchain.tezos.message.request.BroadcastTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.OperationTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.PermissionTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.SignPayloadTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.response.OperationTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.PermissionTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.SignPayloadTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.tezos
import it.airgap.beaconsdk.client.wallet.BeaconWalletClient
import it.airgap.beaconsdk.core.data.BeaconError
import it.airgap.beaconsdk.core.data.P2P
import it.airgap.beaconsdk.core.data.P2pPeer
import it.airgap.beaconsdk.core.data.SigningType
import it.airgap.beaconsdk.core.message.BeaconMessage
import it.airgap.beaconsdk.core.message.BeaconRequest
import it.airgap.beaconsdk.core.message.ErrorBeaconResponse
import it.airgap.beaconsdk.transport.p2p.matrix.p2pMatrix
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.onEach
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
            "connect" ->
                startBeacon()
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
                    val params: HashMap<String, Any> = HashMap();
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
                                        result["expressions"] = value.expressions.map { arg -> getParams(arg) }
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
                                    transaction.parameters?.value?.let { value -> getParams(value) }?.let {
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
    }

    override fun onCancel(arguments: Any?) {
    }

    private var beaconClient: BeaconWalletClient? = null
    private var awaitingRequest: BeaconRequest? = null
    private var requestPublisher = MutableSharedFlow<BeaconRequest>();


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
                            requestPublisher.emit(it)
                        }
                    }
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
                is BroadcastTezosRequest -> ErrorBeaconResponse.from(
                    request,
                    TezosError.BroadcastError
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

}