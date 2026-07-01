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
    @Volatile
    private var lastAttribution: Dictionary = Dictionary()

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
        signals.add(SignalInfo("adid_received", String::class.java))
        signals.add(SignalInfo("google_ad_id_received", String::class.java))
        signals.add(SignalInfo("idfa_received", String::class.java))
        signals.add(SignalInfo("sdk_version_received", String::class.java))
        signals.add(SignalInfo("is_enabled_received", Boolean::class.javaObjectType))
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
            val data = toDictionary(attribution)
            lastAttribution = data
            emitSignal("attribution_changed", data)
        }

        Adjust.initSdk(config)

        Adjust.getAttribution { attribution ->
            if (attribution != null) {
                lastAttribution = toDictionary(attribution)
            }
        }

        emitSignal("initialization_completed")
    }

    @UsedByGodot
    fun track_event(eventToken: String, options: Dictionary) {
        val event = AdjustEvent(eventToken)
        val revenue = (options["revenue"] as? Number)?.toDouble()
        val currency = options["currency"] as? String
        if (revenue != null && !currency.isNullOrEmpty()) {
            event.setRevenue(revenue, currency)
        }
        (options["deduplication_id"] as? String)?.let { event.setDeduplicationId(it) }
        (options["callback_id"] as? String)?.let { event.setCallbackId(it) }
        (options["callback_params"] as? Dictionary)?.let { params ->
            for (key in params.keys) {
                event.addCallbackParameter(key.toString(), params[key].toString())
            }
        }
        (options["partner_params"] as? Dictionary)?.let { params ->
            for (key in params.keys) {
                event.addPartnerParameter(key.toString(), params[key].toString())
            }
        }
        Adjust.trackEvent(event)
    }

    @UsedByGodot
    fun track_third_party_sharing(enabled: Boolean, granularOptions: Dictionary) {
        val sharing = AdjustThirdPartySharing(enabled)
        for (partner in granularOptions.keys) {
            val partnerOptions = granularOptions[partner] as? Dictionary ?: continue
            for (key in partnerOptions.keys) {
                sharing.addGranularOption(partner.toString(), key.toString(), partnerOptions[key].toString())
            }
        }
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
        return lastAttribution
    }

    private fun toDictionary(attribution: AdjustAttribution): Dictionary {
        val data = Dictionary()
        data["tracker_token"] = attribution.trackerToken ?: ""
        data["tracker_name"] = attribution.trackerName ?: ""
        data["network"] = attribution.network ?: ""
        data["campaign"] = attribution.campaign ?: ""
        data["adgroup"] = attribution.adgroup ?: ""
        data["creative"] = attribution.creative ?: ""
        data["click_label"] = attribution.clickLabel ?: ""
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

    @UsedByGodot
    fun set_offline_mode(offline: Boolean) {
        if (offline) Adjust.switchToOfflineMode() else Adjust.switchBackToOnlineMode()
    }

    @UsedByGodot
    fun enable_sdk() {
        Adjust.enable()
    }

    @UsedByGodot
    fun disable_sdk() {
        Adjust.disable()
    }

    @UsedByGodot
    fun request_adid() {
        Adjust.getAdid { adid -> emitSignal("adid_received", adid ?: "") }
    }

    @UsedByGodot
    fun request_google_ad_id() {
        val activity = getActivity() ?: return
        Adjust.getGoogleAdId(activity) { googleAdId -> emitSignal("google_ad_id_received", googleAdId ?: "") }
    }

    @UsedByGodot
    fun request_sdk_version() {
        Adjust.getSdkVersion { version -> emitSignal("sdk_version_received", version ?: "") }
    }

    @UsedByGodot
    fun request_is_enabled() {
        val activity = getActivity() ?: return
        Adjust.isEnabled(activity) { enabled -> emitSignal("is_enabled_received", enabled) }
    }
}
