package com.bitmark.autonomy_flutter.wc2

import kotlinx.serialization.SerialName

@kotlinx.serialization.Serializable
data class Pairing(
    @SerialName("expiry")
    val expiry: Long,
    @SerialName("isActive")
    val isActive: Boolean,
    @SerialName("registeredMethods")
    val registeredMethods: String,
    @SerialName("relayProtocol")
    val relayProtocol: String,
    @SerialName("topic")
    val topic: String,
    @SerialName("uri")
    val uri: String,
    @SerialName("peerAppMetaData")
    val peerAppMetaData: AppMetaData? = null,
    @SerialName("relayData")
    val relayData: String?,
)

fun com.walletconnect.android.Core.Model.Pairing.toPairing(): Pairing {
    return Pairing(
        expiry = this.expiry,
        isActive = this.isActive,
        registeredMethods = this.registeredMethods,
        relayProtocol = this.relayProtocol,
        topic = this.topic,
        uri = this.uri,
        peerAppMetaData = this.peerAppMetaData?.toAppMetaData(),
        relayData = this.relayData,
    )
}