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

import Foundation
import AdjustSdk

@_cdecl("swift_init_adjust_plugin")
public func swift_init_adjust_plugin() {
    print("AdjustGodotPlugin: Initializing...")
}

@_cdecl("swift_deinit_adjust_plugin")
public func swift_deinit_adjust_plugin() {
    print("AdjustGodotPlugin: Deinitializing...")
}

@_cdecl("swift_adjust_initialize")
public func swift_adjust_initialize(appToken: UnsafePointer<Int8>, isSandbox: Bool, attWaitInterval: Int32) {
    let token = String(cString: appToken)
    AdjustGodotPluginSwift.shared.initialize(appToken: token, isSandbox: isSandbox, attWaitInterval: Int(attWaitInterval))
}

@_cdecl("swift_adjust_track_event")
public func swift_adjust_track_event(eventToken: UnsafePointer<Int8>) {
    let token = String(cString: eventToken)
    AdjustGodotPluginSwift.shared.track_event(eventToken: token)
}

@_cdecl("swift_adjust_track_event_with_revenue")
public func swift_adjust_track_event_with_revenue(eventToken: UnsafePointer<Int8>, amount: Double, currency: UnsafePointer<Int8>) {
    let token = String(cString: eventToken)
    let cur = String(cString: currency)
    AdjustGodotPluginSwift.shared.track_event_with_revenue(eventToken: token, amount: amount, currency: cur)
}

@_cdecl("swift_adjust_track_app_store_subscription")
public func swift_adjust_track_app_store_subscription(price: UnsafePointer<Int8>, currency: UnsafePointer<Int8>, transactionId: UnsafePointer<Int8>) {
    let priceStr = String(cString: price)
    let curStr = String(cString: currency)
    let transactionIdStr = String(cString: transactionId)
    AdjustGodotPluginSwift.shared.track_app_store_subscription(price: priceStr, currency: curStr, transactionId: transactionIdStr)
}

@_cdecl("swift_adjust_disable_third_party_sharing")
public func swift_adjust_disable_third_party_sharing() {
    AdjustGodotPluginSwift.shared.disable_third_party_sharing()
}

@_cdecl("swift_adjust_gdpr_forget_me")
public func swift_adjust_gdpr_forget_me() {
    AdjustGodotPluginSwift.shared.gdpr_forget_me()
}

@_cdecl("swift_adjust_set_url_strategy")
public func swift_adjust_set_url_strategy(urls: UnsafePointer<UnsafePointer<Int8>?>, urlCount: Int32, useSubdomains: Bool, isDataResidency: Bool) {
    var urlArray: [String] = []
    for i in 0..<Int(urlCount) {
        if let cString = urls[i] {
            urlArray.append(String(cString: cString))
        }
    }
    AdjustGodotPluginSwift.shared.set_url_strategy(urls: urlArray, useSubdomains: useSubdomains, isDataResidency: isDataResidency)
}

@objc(AdjustGodotPluginSwift)
public class AdjustGodotPluginSwift: NSObject {
    
    @objc public static let shared = AdjustGodotPluginSwift()
    
    private var instance_id: Int64 = 0
    
    public override init() {
        super.init()
    }
    
    @objc public func initialize(appToken: String, isSandbox: Bool, attWaitInterval: Int) {
        let environment = isSandbox ? ADJEnvironmentSandbox : ADJEnvironmentProduction
        let config = ADJConfig(appToken: appToken, environment: environment)
        
        config?.logLevel = isSandbox ? .verbose : .info
        
        // ATT Passthrough: Adjust reads status passively in v5
        config?.attConsentWaitingInterval = UInt(attWaitInterval)
        
        config?.delegate = self
        
        Adjust.initSdk(config)
    }
    
    @objc public func track_event(eventToken: String) {
        let event = ADJEvent(eventToken: eventToken)
        Adjust.trackEvent(event)
    }
    
    @objc public func track_event_with_revenue(eventToken: String, amount: Double, currency: String) {
        let event = ADJEvent(eventToken: eventToken)
        event?.setRevenue(amount, currency: currency)
        Adjust.trackEvent(event)
    }
    
    @objc public func track_app_store_subscription(price: String, currency: String, transactionId: String) {
        let decimalPrice = NSDecimalNumber(string: price)
        if let subscription = ADJAppStoreSubscription(price: decimalPrice, currency: currency, transactionId: transactionId) {
            Adjust.trackAppStoreSubscription(subscription)
        }
    }
    
    @objc public func disable_third_party_sharing() {
        if let sharing = ADJThirdPartySharing(isEnabled: false) {
            Adjust.trackThirdPartySharing(sharing)
        }
    }
    
    @objc public func gdpr_forget_me() {
        print("AdjustGodotPlugin: gdpr_forget_me called. This action is irreversible.")
        Adjust.gdprForgetMe()
    }
    
    @objc public func set_url_strategy(urls: [String], useSubdomains: Bool, isDataResidency: Bool) {
        // Adjust v5 iOS URL strategy is set on config before init
        print("AdjustGodotPlugin: set_url_strategy called. Note: In v5 this must be set on config before initialization.")
    }
}

extension AdjustGodotPluginSwift: AdjustDelegate {
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution = attribution else { return }
        
        var data: [String: Any] = [:]
        data["tracker_token"] = attribution.trackerToken
        data["tracker_name"] = attribution.trackerName
        data["network"] = attribution.network
        data["campaign"] = attribution.campaign
        data["adgroup"] = attribution.adgroup
        data["creative"] = attribution.creative
        data["click_label"] = attribution.clickLabel
        
        // emitSignal("attribution_changed", data)
    }
}
