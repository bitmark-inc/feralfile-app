package com.bitmark.autonomy_flutter

import android.app.Application
import com.bitmark.autonomy_flutter.util.toJsonElement
import com.bitmark.autonomy_flutter.wc2.toPairing
import com.bitmark.autonomy_flutter.wc2.toProposalNamespace
import com.google.gson.Gson
import com.walletconnect.android.Core
import com.walletconnect.android.CoreClient
import com.walletconnect.android.relay.ConnectionType
import com.walletconnect.sign.client.Sign
import com.walletconnect.sign.client.SignClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import it.airgap.beaconsdk.core.message.BeaconRequest
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import timber.log.Timber

class Wc2ConnectPlugin(private val application: Application) : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val WC2_CONNECT_CHANNEL = "wallet_connect_v2"
        private const val WC2_CONNECT_EVENT_CHANNEL = "wallet_connect_v2/event"
        private const val EVENT_NAME = "eventName"
        private const val EVENT_PARAMS = "params"
    }

    private var mainScope: CoroutineScope? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private val pendingRequests = mutableListOf<Sign.Model.SessionRequest>()
    private val pendingProposals = mutableListOf<Sign.Model.SessionProposal>()

    private var eventPublisher = MutableSharedFlow<Any>()

    private fun MethodChannel.Result.success() {
        success(mapOf("result" to 0))
    }

    private fun MethodChannel.Result.error(e: Throwable) {
        error("-1", e.message, null)
    }

    init {
        initClient()
    }

    private fun initClient() {
        // Initialize Wallet Connect
        val appMetadata = Core.Model.AppMetaData(
            name = "Autonomy",
            description = "Autonomy Wallet",
            icons = listOf(),
            url = "autonomy.io",
            redirect = null
        )
        CoreClient.initialize(
            metaData = appMetadata,
            relayServerUrl = "wss://relay.walletconnect.com?projectId=33abc0fd433c7a6e1cc198273e4a7d6e",
            connectionType = ConnectionType.AUTOMATIC,
            application = application,
            relay = null,
            onError = {
                Timber.e("[WalletDelegate] onSessionUpdateResponse $it")
            }
        )
        val signInitParams = Sign.Params.Init(
            core = CoreClient
        )
        SignClient.initialize(signInitParams) { error ->
            Timber.d(error.throwable, "Init SignClient failed")
        }
        val parings = CoreClient.Pairing.getPairings()
        for (p in parings) {
            Timber.d("Paring: $p")
        }

        SignClient.setWalletDelegate(object : SignClient.WalletDelegate {
            override fun onConnectionStateChange(state: Sign.Model.ConnectionState) {
                Timber.d("[WalletDelegate] onConnectionStateChange $state")
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            EVENT_NAME to "onConnectionStateChange",
                            EVENT_PARAMS to mapOf("available" to state.isAvailable)
                        )
                    )
                }
            }

            override fun onError(error: Sign.Model.Error) {
                Timber.d("[WalletDelegate] onError $error")
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            EVENT_NAME to "onError",
                            EVENT_PARAMS to error.throwable.message
                        )
                    )
                }
            }

            override fun onSessionDelete(deletedSession: Sign.Model.DeletedSession) {
                Timber.d("[WalletDelegate] onSessionDelete $deletedSession")
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            EVENT_NAME to "onSessionDelete",
                            EVENT_PARAMS to ""
                        )
                    )
                }
            }

            override fun onSessionProposal(sessionProposal: Sign.Model.SessionProposal) {
                Timber.d("[WalletDelegate] onSessionProposal $sessionProposal")
                pendingProposals.add(sessionProposal)
                val namespaces = sessionProposal.requiredNamespaces.mapValues { e ->
                    e.value.toProposalNamespace()
                }
                val proposer = mapOf(
                    "name" to sessionProposal.name,
                    "url" to sessionProposal.url,
                    "description" to sessionProposal.description,
                    "icons" to sessionProposal.icons.map { it.toString() }
                )
                val params = mapOf(
                    "id" to sessionProposal.proposerPublicKey,
                    "proposer" to Gson().toJson(proposer),
                    "requiredNamespaces" to Json.encodeToString(namespaces)
                )
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            "eventName" to "onSessionProposal",
                            EVENT_PARAMS to params
                        )
                    )
                }
            }

            override fun onSessionRequest(sessionRequest: Sign.Model.SessionRequest) {
                Timber.d("[WalletDelegate] onSessionRequest $sessionRequest")
                pendingRequests.add(sessionRequest)
                val request = mutableMapOf<String, Any?>(
                    "id" to sessionRequest.request.id,
                    "method" to sessionRequest.request.method,
                    "params" to sessionRequest.request.params,
                    "topic" to sessionRequest.topic,
                    "chainId" to sessionRequest.chainId,
                )
                sessionRequest.peerMetaData?.let { proposer ->
                    request["proposer"] = mapOf(
                        "name" to proposer.name,
                        "url" to proposer.url,
                        "description" to proposer.description,
                        "icons" to proposer.icons
                    )
                }
                val params = Json.encodeToString(request.toJsonElement())
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            "eventName" to "onSessionRequest",
                            EVENT_PARAMS to params
                        )
                    )
                }
            }

            override fun onSessionSettleResponse(settleSessionResponse: Sign.Model.SettledSessionResponse) {
                Timber.d("[WalletDelegate] onSessionSettleResponse $settleSessionResponse")
                val params = when (settleSessionResponse) {
                    is Sign.Model.SettledSessionResponse.Result -> {
                        mapOf("topic" to settleSessionResponse.session.topic)
                    }

                    is Sign.Model.SettledSessionResponse.Error -> {
                        mapOf("error" to settleSessionResponse.errorMessage)
                    }
                }
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            EVENT_NAME to "onSessionSettle",
                            EVENT_PARAMS to params
                        )
                    )
                }
            }

            override fun onSessionUpdateResponse(sessionUpdateResponse: Sign.Model.SessionUpdateResponse) {
                Timber.d("[WalletDelegate] onSessionUpdateResponse $sessionUpdateResponse")
                val params = when (sessionUpdateResponse) {
                    is Sign.Model.SessionUpdateResponse.Result -> {
                        mapOf(
                            "topic" to sessionUpdateResponse.topic,
                            "namespaces" to sessionUpdateResponse.namespaces
                        )
                    }

                    is Sign.Model.SessionUpdateResponse.Error -> {
                        mapOf("error" to sessionUpdateResponse.errorMessage)
                    }
                }
                mainScope?.launch {
                    eventPublisher.emit(
                        mapOf(
                            EVENT_NAME to "onSessionUpdate",
                            EVENT_PARAMS to params
                        )
                    )
                }
            }
        })
    }

    private fun pairClient(uri: String, result: MethodChannel.Result) {
        Timber.d("Pair client: $uri")
        try {
            CoreClient.Pairing.pair(Core.Params.Pair(uri), onError = { e ->
                Timber.e(e.throwable, "Pair client failed")
            })
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Pair client failed")
            result.error(e)
        }
    }

    private fun approve(proposalId: String, account: String, result: MethodChannel.Result) {
        Timber.d("Approve proposal: $proposalId, account: $account")
        val proposal =
            pendingProposals.firstOrNull { it.proposerPublicKey == proposalId }
        if (proposal == null) {
            result.error("-1", "Proposal not found", null)
            return
        }
        val namespaces = proposal.requiredNamespaces.mapValues {
            Sign.Model.Namespace.Session(
                chains = it.value.chains,
                methods = it.value.methods,
                events = it.value.events,
                accounts = it.value.chains?.map { chain -> "$chain:$account" } ?: emptyList(),
            )
        }
        try {
            SignClient.approveSession(
                Sign.Params.Approve(
                    proposerPublicKey = proposalId,
                    namespaces = namespaces,
                    relayProtocol = proposal.relayProtocol
                ),
                onError = { e ->
                    Timber.e(e.throwable, "Approve session failed")
                })
            pendingProposals.remove(proposal)
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Approve session failed")
            result.error(e)
        }
    }

    private fun reject(proposalId: String, reason: String, result: MethodChannel.Result) {
        val proposal =
            pendingProposals.firstOrNull { it.proposerPublicKey == proposalId }
        if (proposal == null) {
            result.error("", "Proposal not found $proposalId", null)
            return
        }
        try {
            SignClient.rejectSession(
                Sign.Params.Reject(
                    proposerPublicKey = proposalId,
                    reason = reason.ifBlank { "disapprovedChains" }
                ),
                onError = { e ->
                    Timber.e(e.throwable, "Reject session failed")
                })
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Reject session failed")
            result.error(e)
        }
    }

    private fun respondOnApprove(topic: String, response: String, result: MethodChannel.Result) {
        val request = pendingRequests.firstOrNull { e -> e.topic == topic }
        if (request == null) {
            result.error("", "Request not found", null)
            return
        }
        val jsonRpcResponse = Sign.Model.JsonRpcResponse.JsonRpcResult(
            id = request.request.id,
            result = response
        )
        try {
            SignClient.respond(
                Sign.Params.Response(
                    sessionTopic = topic,
                    jsonRpcResponse = jsonRpcResponse
                ), onError = { e ->
                    Timber.e(e.throwable, "Reject session failed")
                })
            pendingRequests.remove(request)
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Approval respond failed")
            result.error(e)
        }
    }

    private fun respondOnReject(topic: String, reason: String, result: MethodChannel.Result) {
        try {
            val request = pendingRequests.firstOrNull { e -> e.topic == topic }
            if (request == null) {
                result.error("", "Request not found", null)
                return
            }
            SignClient.respond(
                Sign.Params.Response(
                    topic,
                    Sign.Model.JsonRpcResponse.JsonRpcError(request.request.id, 0, reason)
                ),
                onError = { e ->
                    Timber.e(e.throwable, "Reject session failed")
                })
            request.let {
                pendingRequests.remove(it)
            }
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Reject session failed")
            result.error(e)
        }
    }

    private fun getPairings(result: MethodChannel.Result) {
        try {
            val pairings = CoreClient.Pairing.getPairings().map { e -> e.toPairing() }
            val json = Json.encodeToString(pairings)
            result.success(json)
        } catch (e: Throwable) {
            result.error(e)
        }
    }

    private fun deletePairing(topic: String, result: MethodChannel.Result) {
        try {
            Timber.e("Delete pairing. Topic: $topic")
            CoreClient.Pairing.disconnect(topic, onError = { e ->
                Timber.e(e.throwable, "Delete pairing error")
            })
            result.success()
        } catch (e: Throwable) {
            Timber.e(e, "Delete pairing error")
            result.error(e)
        }
    }

    private fun cleanupSessions(retainIds: List<String>, result: MethodChannel.Result) {
        Timber.e("cleanupSessions. Topic: $retainIds")
        val pairings = CoreClient.Pairing.getPairings().map { e -> e.toPairing() }

        pairings.forEach {
            if (!retainIds.contains(it.topic)) {
                CoreClient.Pairing.disconnect(it.topic)
            }
        }
        result.success()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pairClient" -> {
                val uri = call.argument<String?>("uri").orEmpty()
                pairClient(uri, result)
            }

            "approve" -> {
                val proposalId = call.argument<String?>("proposal_id").orEmpty()
                val account = call.argument<String?>("account").orEmpty()
                approve(proposalId, account, result)
            }

            "reject" -> {
                val proposalId = call.argument<String?>("proposal_id").orEmpty()
                val reason = call.argument<String?>("reason").orEmpty()
                reject(proposalId, reason, result)
            }

            "respondOnApprove" -> {
                val topic = call.argument<String?>("topic").orEmpty()
                val response = call.argument<String?>("response").orEmpty()
                respondOnApprove(topic, response, result)
            }

            "respondOnReject" -> {
                val topic = call.argument<String?>("topic").orEmpty()
                val reason = call.argument<String?>("reason").orEmpty()
                respondOnReject(topic, reason, result)
            }

            "getPairings" -> {
                getPairings(result)
            }

            "deletePairing" -> {
                val topic = call.argument<String?>("topic").orEmpty()
                deletePairing(topic = topic, result = result)
            }

            "cleanup" -> {
                val retainIds: List<String> = call.argument("retain_ids") ?: emptyList()
                cleanupSessions(retainIds, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        mainScope?.launch {
            eventPublisher
                .onEach { }
                .collect { event ->
                    events?.success(event)
                }
        }
    }

    override fun onCancel(arguments: Any?) {

    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.d("onAttachedToEngine")
        mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
        initialize(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.d("onDetachedFromEngine")
        mainScope?.cancel()
        eventChannel?.setStreamHandler(null)
        methodChannel?.setMethodCallHandler(null)
    }

    private fun initialize(binaryMessenger: BinaryMessenger) {
        methodChannel = MethodChannel(binaryMessenger, WC2_CONNECT_CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        eventChannel = EventChannel(binaryMessenger, WC2_CONNECT_EVENT_CHANNEL)
        eventChannel?.setStreamHandler(this)
    }
}