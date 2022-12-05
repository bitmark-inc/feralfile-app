package com.bitmark.autonomy_flutter.wc2

import com.walletconnect.sign.client.Sign
import kotlinx.serialization.SerialName

@kotlinx.serialization.Serializable
data class SessionRequest(
    @SerialName("topic")
    val topic: String,
    @SerialName("chainId")
    val chainId: String?,
    @SerialName("peerMetaData")
    val peerMetaData: AppMetaData?,
    @SerialName("request")
    val request: JSONRPCRequest
) {
    @kotlinx.serialization.Serializable
    data class JSONRPCRequest(
        @SerialName("id")
        val id: Long,
        @SerialName("method")
        val method: String,
        @SerialName("params")
        val params: String,
    )
}

fun Sign.Model.SessionRequest.JSONRPCRequest.toJsonRPCRequest(): SessionRequest.JSONRPCRequest {
    return SessionRequest.JSONRPCRequest(
        id = this.id,
        method = this.method,
        params = this.params
    )
}

fun Sign.Model.SessionRequest.toSessionRequest(): SessionRequest {
    return SessionRequest(
        topic = this.topic,
        chainId = this.chainId,
        peerMetaData = this.peerMetaData?.toAppMetaData(),
        request = this.request.toJsonRPCRequest()
    )
}