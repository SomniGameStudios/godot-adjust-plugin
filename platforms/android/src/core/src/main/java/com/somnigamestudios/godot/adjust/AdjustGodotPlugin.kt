// MIT License
//
// Copyright (c) 2026-present Somni Game Studios
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package com.somnigamestudios.godot.adjust

import android.app.Activity
import android.util.Log
import com.adjust.sdk.*
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class AdjustGodotPlugin(godot: Godot) : GodotPlugin(godot) {

    private var cachedUrls: Array<String>? = null
    private var cachedUseSubdomains: Boolean = false
    private var cachedIsDataResidency: Boolean = false
    private var lastAttribution: AdjustAttribution? = null

    companion object {
        private const val TAG = "AdjustGodotPlugin"
    }

    override fun getPluginName(): String {
        return "AdjustGodotPlugin"
    }

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        val signals = mutableSetOf<SignalInfo>()
        signals.add(SignalInfo("attribution_changed", Dictionary::class.java))
        signals.add(SignalInfo("initialization_completed"))
        return signals
    }

    @UsedByGodot
    fun initialize(appToken: String, isSandbox: Boolean, attWaitInterval: Int, fbAppId: String) {
        val activity = getActivity()
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot initialize Adjust")
            return
        }

        val environment = if (isSandbox) AdjustConfig.ENVIRONMENT_SANDBOX else AdjustConfig.ENVIRONMENT_PRODUCTION
        val config = AdjustConfig(activity, appToken, environment)

        config.setLogLevel(if (isSandbox) LogLevel.VERBOSE else LogLevel.WARN)

        if (fbAppId.isNotEmpty()) {
            config.fbAppId = fbAppId
        }

        cachedUrls?.let { urls ->
            config.setUrlStrategy(urls.toList(), cachedUseSubdomains, cachedIsDataResidency)
        }

        config.setOnAttributionChangedListener { attribution ->
            lastAttribution = attribution
            val data = Dictionary()
            data["tracker_token"] = attribution.trackerToken
            data["tracker_name"] = attribution.trackerName
            data["network"] = attribution.network
            data["campaign"] = attribution.campaign
            data["adgroup"] = attribution.adgroup
            data["creative"] = attribution.creative
            data["click_label"] = attribution.clickLabel
            
            emitSignal("attribution_changed", data)
        }

        Adjust.initSdk(config)

        Adjust.getAttribution { attribution ->
            lastAttribution = attribution
        }

        emitSignal("initialization_completed")
    }

    @UsedByGodot
    fun track_event(eventToken: String) {
        val event = AdjustEvent(eventToken)
        Adjust.trackEvent(event)
    }

    @UsedByGodot
    fun track_event_with_revenue(eventToken: String, amount: Double, currency: String) {
        val event = AdjustEvent(eventToken)
        event.setRevenue(amount, currency)
        Adjust.trackEvent(event)
    }

    @UsedByGodot
    fun disable_third_party_sharing() {
        val sharing = AdjustThirdPartySharing(false)
        Adjust.trackThirdPartySharing(sharing)
    }

    @UsedByGodot
    fun track_play_store_subscription(price: Long, currency: String, sku: String, orderId: String, signature: String, purchaseToken: String) {
        val subscription = AdjustPlayStoreSubscription(price, currency, sku, orderId, signature, purchaseToken)
        Adjust.trackPlayStoreSubscription(subscription)
    }

    @UsedByGodot
    fun gdpr_forget_me() {
        val activity = getActivity()
        if (activity != null) {
            Log.w(TAG, "gdpr_forget_me called. This action is irreversible.")
            Adjust.gdprForgetMe(activity)
        }
    }

    @UsedByGodot
    fun set_url_strategy(urls: Array<String>, useSubdomains: Boolean, isDataResidency: Boolean) {
        cachedUrls = urls
        cachedUseSubdomains = useSubdomains
        cachedIsDataResidency = isDataResidency
    }

    @UsedByGodot
    fun get_attribution(): Dictionary {
        val data = Dictionary()
        val attribution = lastAttribution
        if (attribution != null) {
            data["tracker_token"] = attribution.trackerToken ?: ""
            data["tracker_name"] = attribution.trackerName ?: ""
            data["network"] = attribution.network ?: ""
            data["campaign"] = attribution.campaign ?: ""
            data["adgroup"] = attribution.adgroup ?: ""
            data["creative"] = attribution.creative ?: ""
            data["click_label"] = attribution.clickLabel ?: ""
        }
        return data
    }

    @UsedByGodot
    fun track_measurement_consent(enabled: Boolean) {
        Adjust.trackMeasurementConsent(enabled)
    }

    @UsedByGodot
    fun track_ad_revenue(source: String, revenue: Double, currency: String) {
        val adRevenue = AdjustAdRevenue(source)
        adRevenue.setRevenue(revenue, currency)
        Adjust.trackAdRevenue(adRevenue)
    }
}
