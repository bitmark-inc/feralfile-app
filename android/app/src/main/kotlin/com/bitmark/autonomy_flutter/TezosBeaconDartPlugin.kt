/* SPDX-License-Identifier: BSD-2-Clause-Patent
 * Copyright © 2022 Bitmark. All rights reserved.
 * Use of this source code is governed by the BSD-2-Clause Plus Patent License
 * that can be found in the LICENSE file.
 */

import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat.getSystemService
import com.bitmark.autonomy_flutter.FileLogger
import com.bitmark.autonomy_flutter.jsonKT
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import it.airgap.beaconsdk.blockchain.substrate.substrate
import it.airgap.beaconsdk.blockchain.tezos.data.TezosAccount
import it.airgap.beaconsdk.blockchain.tezos.data.TezosPermission
import it.airgap.beaconsdk.blockchain.tezos.data.TezosNetwork
import it.airgap.beaconsdk.blockchain.tezos.data.operation.*
import it.airgap.beaconsdk.blockchain.tezos.internal.wallet.*
import it.airgap.beaconsdk.blockchain.tezos.message.request.BroadcastTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.OperationTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.PermissionTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.request.SignPayloadTezosRequest
import it.airgap.beaconsdk.blockchain.tezos.message.response.OperationTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.PermissionTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.message.response.SignPayloadTezosResponse
import it.airgap.beaconsdk.blockchain.tezos.tezos
import it.airgap.beaconsdk.client.wallet.BeaconWalletClient
import it.airgap.beaconsdk.client.wallet.compat.stop
import it.airgap.beaconsdk.core.data.*
import it.airgap.beaconsdk.core.internal.data.HexString
import it.airgap.beaconsdk.core.internal.utils.*
import it.airgap.beaconsdk.core.message.BeaconMessage
import it.airgap.beaconsdk.core.message.BeaconRequest
import it.airgap.beaconsdk.core.message.ErrorBeaconResponse
import it.airgap.beaconsdk.core.scope.BeaconScope
import it.airgap.beaconsdk.transport.p2p.matrix.p2pMatrix
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.*
import java.util.*

class TezosBeaconDartPlugin : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var isNetworkDisconnected = false

    fun createChannels(@NonNull flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tezos_beacon")
        channel.setMethodCallHandler(this)
        eventChannel =
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, "tezos_beacon/event")
        eventChannel.setStreamHandler(this)

        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
            .build()
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: android.net.Network) {
                super.onAvailable(network)
                if (isNetworkDisconnected) {
                    startBeacon()
                    isNetworkDisconnected = false
                }
            }

            override fun onLost(network: android.net.Network) {
                super.onLost(network)
                isNetworkDisconnected = true
            }
        }

        val connectivityManager = getSystemService(
            applicationContext,
            ConnectivityManager::class.java
        ) as ConnectivityManager
        connectivityManager.requestNetwork(networkRequest, networkCallback)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "connect" -> {
                startBeacon()
            }

            "addPeer" -> {
                val link: String = call.argument("link") ?: ""
                addPeer(link, result)
            }

            "removePeer" -> {
                val peer: String = call.argument("peer") ?: ""
                removePeer(peer, result)
            }

            "removePeers" -> removePeers()
            "cleanup" -> {
                val retainIds: List<String> = call.argument("retain_ids") ?: emptyList()
                cleanupSessions(retainIds, result)
            }

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
                                        result["bytes"] =
                                            if (value.bytes.isEmpty()) "" else HexString(value.bytes).asString(
                                                withPrefix = false
                                            )
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
                                        transaction.parameters?.value?.let { value ->
                                            getParams(
                                                value
                                            )
                                        }
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

                    FileLogger.log("TezosBeaconDartPlugin", "new request: $rev")

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

                    dependencyRegistry(BeaconScope.Global).crypto

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
            beaconClient?.stop()
            beaconClient = BeaconWalletClient(
                "Autonomy",
            ) {
                support(tezos(), substrate())
                use(p2pMatrix())

                ignoreUnsupportedBlockchains = true
            }

            launch {
                beaconClient?.connect()
                    ?.catch { error ->
                        FileLogger.log(
                            "TezosBeaconDartPlugin",
                            "connect: ${error.message}"
                        )
                    }
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
                    val address: String? = call.argument("address")

                    publicKey?.let {

                        PermissionTezosResponse.from(
                            request,
                            TezosAccount(
                                publicKey = it,
                                address = address ?: "",
                                network = TezosNetwork.Mainnet(),
                                beaconScope = BeaconScope.Global

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
            FileLogger.log("TezosBeaconDartPlugin", "respond to id: $id")
            beaconClient?.respond(response)
            removeAwaitingRequest()
            result.success(mapOf("error" to 0))
        }
    }

    private fun addPeer(link: String, result: Result) {
        FileLogger.log("TezosBeaconDartPlugin", "addPeer: $link")
        val peer = extractPeer(link) ?: run {
            FileLogger.log("TezosBeaconDartPlugin", "addPeer: error invalid link")
            return
        }
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.addPeers(peer)
            val jsonPeer = jsonKT.encodeToString(peer)
            FileLogger.log("TezosBeaconDartPlugin", "peer added: $jsonPeer")
            result.success(mapOf("error" to 0, "result" to jsonPeer))
        }
    }

    private fun removePeers() {
        FileLogger.log("TezosBeaconDartPlugin", "removePeers")
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.removeAllPeers()
        }
    }

    private fun removePeer(peerJson: String, result: Result) {
        FileLogger.log("TezosBeaconDartPlugin", "removePeer")
        CoroutineScope(Dispatchers.IO).launch {
            val peer = jsonKT.decodeFromString(
                P2pPeer.serializer(),
                peerJson
            )
            beaconClient?.removePeers(peer)
            result.success(mapOf("error" to 0))
        }
    }

    private fun cleanupSessions(retainIds: List<String>, result: Result) {
        FileLogger.log("TezosBeaconDartPlugin", "cleanupSessions retainsIds: $retainIds")
        CoroutineScope(Dispatchers.IO).launch {
            beaconClient?.getPeers()?.let { peers ->
                val peer: List<Peer> = peers.filterNot { peer -> retainIds.any { it == peer.id } }
                beaconClient?.removePeers(peer)
            }
            result.success(mapOf("error" to 0))
        }
    }

    private fun saveAwaitingRequest(message: BeaconMessage) {
        awaitingRequest = if (message is BeaconRequest) message else null
    }

    private fun removeAwaitingRequest() {
        awaitingRequest = null
    }

    private fun extractPeer(link: String): P2pPeer? {
        val uri = Uri.parse(link)
        val message = uri.getQueryParameter("data") ?: return null
        val messageData =
            beaconSdk.dependencyRegistry(BeaconScope.Global).base58Check.decode(message).getOrNull()
                ?: return null

        return jsonKT.decodeFromString(messageData.toString(Charsets.UTF_8))
    }
}

data class TezosWalletConnection(
    @SerialName("address")
    val address: String,
    @SerialName("peer")
    val peer: Peer?,
    @SerialName("permissionResponse")
    val permissionResponse: PermissionTezosResponse
)