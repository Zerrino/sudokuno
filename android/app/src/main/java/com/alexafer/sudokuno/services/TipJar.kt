package com.alexafer.sudokuno.services

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.alexafer.sudokuno.i18n.L
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams

/**
 * Pot à pourboires : dons facultatifs, produits « consommables » Google Play qui ne débloquent rien.
 * Identifiants identiques à iOS. « Montant libre » : l'achat multiple (quantité) se règle dans la fenêtre
 * de paiement Google Play, si l'option est activée sur le produit dans la console.
 */
class TipJar(context: Context) : PurchasesUpdatedListener {
    enum class Tip(val id: String, val emoji: String) {
        SMALL("com.alexafer.sudokuno.tip.small", "☕️"),
        MEDIUM("com.alexafer.sudokuno.tip.medium", "☕️☕️"),
        LARGE("com.alexafer.sudokuno.tip.large", "☕️🥐");

        val displayName: String
            get() = when (this) {
                SMALL -> L("Petit café")
                MEDIUM -> L("Grand café")
                LARGE -> L("Café et croissant")
            }

        companion object { fun of(id: String) = entries.firstOrNull { it.id == id } }
    }

    enum class Status { IDLE, PURCHASING, THANKED, PENDING, FAILED }

    var products by mutableStateOf<List<ProductDetails>>(emptyList()); private set
    var loaded by mutableStateOf(false); private set
    var status by mutableStateOf(Status.IDLE)
    var purchasingId by mutableStateOf<String?>(null); private set

    private val prefs = context.getSharedPreferences("tips", Context.MODE_PRIVATE)
    var tipCount by mutableIntStateOf(prefs.getInt("tipCount", 0)); private set

    private val client = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    fun load() {
        if (client.isReady) { query(); return }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    query()
                    finishPending()
                } else {
                    loaded = true
                }
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun query() {
        val params = QueryProductDetailsParams.newBuilder().setProductList(
            Tip.entries.map {
                QueryProductDetailsParams.Product.newBuilder().setProductId(it.id).setProductType(BillingClient.ProductType.INAPP).build()
            }
        ).build()
        client.queryProductDetailsAsync(params) { _, result ->
            products = result.productDetailsList.sortedBy { priceMicros(it) }
            loaded = true
        }
    }

    fun buy(activity: Activity, product: ProductDetails) {
        purchasingId = product.productId
        status = Status.PURCHASING
        val params = BillingFlowParams.newBuilder().setProductDetailsParamsList(
            listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product).build())
        ).build()
        val r = client.launchBillingFlow(activity, params)
        if (r.responseCode != BillingClient.BillingResponseCode.OK) { status = Status.FAILED; purchasingId = null }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        purchasingId = null
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> purchases.orEmpty().forEach { handle(it, thank = true) }
            BillingClient.BillingResponseCode.USER_CANCELED -> status = Status.IDLE
            else -> status = Status.FAILED
        }
    }

    private fun handle(p: Purchase, thank: Boolean) {
        when (p.purchaseState) {
            Purchase.PurchaseState.PURCHASED -> {
                client.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(p.purchaseToken).build()) { r, _ ->
                    if (r.responseCode == BillingClient.BillingResponseCode.OK) {
                        tipCount += 1
                        prefs.edit().putInt("tipCount", tipCount).apply()
                        if (thank) status = Status.THANKED
                    }
                }
            }
            Purchase.PurchaseState.PENDING -> if (thank) status = Status.PENDING
            else -> {}
        }
    }

    /** Dons validés plus tard (paiement en attente) : à consommer au démarrage. */
    private fun finishPending() {
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { _, list ->
            list.forEach { handle(it, thank = false) }
        }
    }

    companion object {
        fun priceMicros(p: ProductDetails): Long = p.oneTimePurchaseOfferDetailsList?.firstOrNull()?.priceAmountMicros ?: 0L
        fun formattedPrice(p: ProductDetails): String = p.oneTimePurchaseOfferDetailsList?.firstOrNull()?.formattedPrice ?: ""
    }
}
