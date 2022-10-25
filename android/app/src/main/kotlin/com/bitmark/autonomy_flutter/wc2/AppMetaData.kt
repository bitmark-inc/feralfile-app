package com.bitmark.autonomy_flutter.wc2

import com.walletconnect.android.Core
import kotlinx.serialization.SerialName

@kotlinx.serialization.Serializable
data class AppMetaData(
    @SerialName("name")
    val name: String,
    @SerialName("description")
    val description: String,
    @SerialName("url")
    val url: String,
    @SerialName("icons")
    val icons: List<String>,
    @SerialName("redirect")
    val redirect: String?
)

fun Core.Model.AppMetaData.toAppMetaData(): AppMetaData {
    return AppMetaData(
        name = this.name,
        description = this.description,
        url = this.url,
        icons = this.icons,
        redirect = this.redirect
    )
}