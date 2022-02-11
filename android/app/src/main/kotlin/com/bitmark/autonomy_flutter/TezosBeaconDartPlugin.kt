import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.github.novacrypto.base58.Base58
import it.airgap.beaconsdk.blockchain.tezos.data.TezosError
import it.airgap.beaconsdk.blockchain.tezos.message.request.BroadcastTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.OperationTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.PermissionTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.SignPayloadTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.response.PermissionTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.tezos
import it.airgap.beaconsdk.client.wallet.BeaconWalletClient
import it.airgap.beaconsdk.core.data.BeaconError
import it.airgap.beaconsdk.core.data.P2P
import it.airgap.beaconsdk.core.data.P2pPeer
import it.airgap.beaconsdk.core.message.BeaconMessage
import it.airgap.beaconsdk.core.message.BeaconRequest
import it.airgap.beaconsdk.core.message.ErrorBeaconResponse
import it.airgap.beaconsdk.transport.p2p.matrix.p2pMatrix
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import java.util.*

@DelicateCoroutinesApi
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
                respond()
            "pause", "resume" -> result.success("")
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        GlobalScope.launch {
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
                            params["icon"] = permissionRequest.appMetadata.icon ?: ""
                            params["appName"] = permissionRequest.appMetadata.name
                        }
                        is SignPayloadTezosRequest -> {
                            val signPayload: SignPayloadTezosRequest = request

                            params["type"] = "signPayload"
                            params["icon"] = signPayload.appMetadata?.icon ?: ""
                            params["appName"] = signPayload.appMetadata?.name ?: ""
                            params["payload"] = signPayload.payload
                            params["sourceAddress"] = signPayload.sourceAddress
                        }
                        is OperationTezosRequest -> {
                            params["type"] = "operation"
                        }
                        else -> {
                        }
                    }

                    rev["eventName"] = "observeRequest"
                    rev["params"] = params

                    events?.success(rev)
                }
        }
    }

    override fun onCancel(arguments: Any?) {
    }

    private var beaconClient: BeaconWalletClient? = null
    private var awaitingRequest: BeaconRequest? = null
    private val requestPublisher = MutableSharedFlow<BeaconRequest>();


    private fun startBeacon() {
        GlobalScope.launch {
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

            beaconClient?.connect()
                ?.onEach { result ->
                    Log.d("123123", result.toString())
//                    result.getOrNull()
                }
                ?.collect { result ->
                    result.getOrNull()?.let {
                        requestPublisher.emit(it)
                    }
                }
        }
    }

    private fun respond() {
        val request = awaitingRequest ?: return

        GlobalScope.launch {
            val response = when (request) {
                is PermissionTezosRequest -> PermissionTezosResponse.from(
                    request,
                    "edpktpzo8UZieYaJZgCHP6M6hKHPdWBSNqxvmEt6dwWRgxDh1EAFw9"
                )
                is OperationTezosRequest -> ErrorBeaconResponse.from(request, BeaconError.Aborted)
                is SignPayloadTezosRequest -> ErrorBeaconResponse.from(
                    request,
                    TezosError.SignatureTypeNotSupported
                )
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
        GlobalScope.launch {
            beaconClient?.addPeers(peer)
        }
    }

    private fun removePeers() {
        GlobalScope.launch {
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

        Log.d("123123", messageData.toString(Charsets.UTF_8))

        val json = messageData.toString(Charsets.UTF_8).substringAfter("{").substringBeforeLast("}")

        return Json { ignoreUnknownKeys = true }.decodeFromString("{$json}")
    }

}