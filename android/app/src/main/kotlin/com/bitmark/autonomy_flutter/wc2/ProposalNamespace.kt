package com.bitmark.autonomy_flutter.wc2

import com.walletconnect.sign.client.Sign
import kotlinx.serialization.SerialName

@kotlinx.serialization.Serializable
data class ProposalNamespace(
    @SerialName("chains")
    val chains: List<String>,
    @SerialName("methods")
    val methods: List<String>,
    @SerialName("events")
    val events: List<String>,
    @SerialName("extensions")
    val extensions: List<Extension>? = null
)

@kotlinx.serialization.Serializable
data class Extension(
    @SerialName("chains")
    val chains: List<String>,
    @SerialName("methods")
    val methods: List<String>,
    @SerialName("events")
    val events: List<String>
)

fun Sign.Model.Namespace.Proposal.toProposalNamespace(): ProposalNamespace {
    return ProposalNamespace(
        chains = this.chains ?: emptyList(),
        methods = this.methods,
        events = this.events,
    )
}