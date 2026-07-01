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

#import <Foundation/Foundation.h>
#import <AppTrackingTransparency/ATTrackingManager.h>
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>
#import <AdjustSdk/ADJEvent.h>
#import <AdjustSdk/ADJAttribution.h>
#import <AdjustSdk/ADJThirdPartySharing.h>
#import <AdjustSdk/ADJAppStoreSubscription.h>
#import <AdjustSdk/ADJLogger.h>
#import <AdjustSdk/ADJAdRevenue.h>
#include "core/config/engine.h"
#include "core/object/class_db.h"

class AdjustGodotPlugin : public Object {
    GDCLASS(AdjustGodotPlugin, Object);

    static AdjustGodotPlugin *instance;

    PackedStringArray cached_urls;
    bool cached_use_subdomains = false;
    bool cached_is_data_residency = false;
    bool has_cached_urls = false;

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("initialize", "app_token", "is_sandbox", "att_wait_interval", "fb_app_id"), &AdjustGodotPlugin::initialize);
        ClassDB::bind_method(D_METHOD("track_event", "event_token"), &AdjustGodotPlugin::track_event);
        ClassDB::bind_method(D_METHOD("track_event_with_revenue", "event_token", "amount", "currency"), &AdjustGodotPlugin::track_event_with_revenue);
        ClassDB::bind_method(D_METHOD("track_app_store_subscription", "price", "currency", "transaction_id"), &AdjustGodotPlugin::track_app_store_subscription);
        ClassDB::bind_method(D_METHOD("disable_third_party_sharing"), &AdjustGodotPlugin::disable_third_party_sharing);
        ClassDB::bind_method(D_METHOD("gdpr_forget_me"), &AdjustGodotPlugin::gdpr_forget_me);
        ClassDB::bind_method(D_METHOD("set_url_strategy", "urls", "use_subdomains", "is_data_residency"), &AdjustGodotPlugin::set_url_strategy);
        ClassDB::bind_method(D_METHOD("request_tracking_authorization"), &AdjustGodotPlugin::request_tracking_authorization);
        ClassDB::bind_method(D_METHOD("get_attribution"), &AdjustGodotPlugin::get_attribution);
        ClassDB::bind_method(D_METHOD("track_measurement_consent", "enabled"), &AdjustGodotPlugin::track_measurement_consent);
        ClassDB::bind_method(D_METHOD("track_ad_revenue", "source", "revenue", "currency"), &AdjustGodotPlugin::track_ad_revenue);
        
        ADD_SIGNAL(MethodInfo("attribution_changed", PropertyInfo(Variant::DICTIONARY, "data")));
        ADD_SIGNAL(MethodInfo("initialization_completed"));
    }

public:
    Dictionary last_attribution;

    void initialize(String p_app_token, bool p_is_sandbox, int p_att_wait_interval, String p_fb_app_id);
    void track_event(String p_event_token);
    void track_event_with_revenue(String p_event_token, double p_amount, String p_currency);
    void track_app_store_subscription(String p_price, String p_currency, String p_transaction_id);
    void disable_third_party_sharing();
    void gdpr_forget_me();
    void set_url_strategy(PackedStringArray p_urls, bool p_use_subdomains, bool p_is_data_residency);
    void request_tracking_authorization();
    Dictionary get_attribution();
    void track_measurement_consent(bool p_enabled);
    void track_ad_revenue(String p_source, double p_revenue, String p_currency);

    static AdjustGodotPlugin *get_singleton() {
        return instance;
    }

    AdjustGodotPlugin() {
        instance = this;
    }

    ~AdjustGodotPlugin() {
        instance = nullptr;
    }
};

AdjustGodotPlugin *AdjustGodotPlugin::instance = nullptr;

static Dictionary adjust_attribution_to_dict(ADJAttribution *attribution) {
    Dictionary data;
    if (attribution == nil) return data;
    data["tracker_token"] = attribution.trackerToken ? String::utf8([attribution.trackerToken UTF8String]) : "";
    data["tracker_name"] = attribution.trackerName ? String::utf8([attribution.trackerName UTF8String]) : "";
    data["network"] = attribution.network ? String::utf8([attribution.network UTF8String]) : "";
    data["campaign"] = attribution.campaign ? String::utf8([attribution.campaign UTF8String]) : "";
    data["adgroup"] = attribution.adgroup ? String::utf8([attribution.adgroup UTF8String]) : "";
    data["creative"] = attribution.creative ? String::utf8([attribution.creative UTF8String]) : "";
    data["click_label"] = attribution.clickLabel ? String::utf8([attribution.clickLabel UTF8String]) : "";
    return data;
}

@interface AdjustGodotDelegate : NSObject <AdjustDelegate>
+ (instancetype)sharedInstance;
@end

@implementation AdjustGodotDelegate

+ (instancetype)sharedInstance {
    static AdjustGodotDelegate *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AdjustGodotDelegate alloc] init];
    });
    return shared;
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    if (attribution == nil) return;
    Dictionary data = adjust_attribution_to_dict(attribution);
    dispatch_async(dispatch_get_main_queue(), ^{
        AdjustGodotPlugin *plugin = AdjustGodotPlugin::get_singleton();
        if (plugin) {
            plugin->last_attribution = data;
            plugin->emit_signal("attribution_changed", data);
        }
    });
}

@end

void AdjustGodotPlugin::initialize(String p_app_token, bool p_is_sandbox, int p_att_wait_interval, String p_fb_app_id) {
    NSString *appTokenStr = [NSString stringWithUTF8String:p_app_token.utf8().get_data()];
    NSString *environment = p_is_sandbox ? ADJEnvironmentSandbox : ADJEnvironmentProduction;

    ADJConfig *config = [[ADJConfig alloc] initWithAppToken:appTokenStr environment:environment];
    if (config == nil) {
        NSLog(@"AdjustGodotPlugin: Failed to create ADJConfig");
        return;
    }

    [config setLogLevel:p_is_sandbox ? ADJLogLevelVerbose : ADJLogLevelWarn];
    [config setAttConsentWaitingInterval:(NSUInteger)p_att_wait_interval];
    [config setDelegate:[AdjustGodotDelegate sharedInstance]];

    // iOS has no Facebook App ID setter; the SDK reads the FB attribution ID
    // automatically. fb_app_id only applies to the Android Meta Install Referrer.
    (void)p_fb_app_id;

    if (has_cached_urls) {
        NSMutableArray *urlArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < cached_urls.size(); i++) {
            NSString *urlStr = [NSString stringWithUTF8String:cached_urls[i].utf8().get_data()];
            [urlArray addObject:urlStr];
        }
        [config setUrlStrategy:urlArray
                 useSubdomains:cached_use_subdomains ? YES : NO
                isDataResidency:cached_is_data_residency ? YES : NO];
    }
    
    [Adjust initSdk:config];
    
    [Adjust attributionWithCompletionHandler:^(ADJAttribution * _Nullable attribution) {
        if (attribution == nil) return;
        Dictionary data = adjust_attribution_to_dict(attribution);
        dispatch_async(dispatch_get_main_queue(), ^{
            AdjustGodotPlugin *plugin = AdjustGodotPlugin::get_singleton();
            if (plugin) {
                plugin->last_attribution = data;
            }
        });
    }];
    
    emit_signal("initialization_completed");
}

void AdjustGodotPlugin::track_event(String p_event_token) {
    NSString *eventTokenStr = [NSString stringWithUTF8String:p_event_token.utf8().get_data()];
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:eventTokenStr];
    [Adjust trackEvent:event];
}

void AdjustGodotPlugin::track_event_with_revenue(String p_event_token, double p_amount, String p_currency) {
    NSString *eventTokenStr = [NSString stringWithUTF8String:p_event_token.utf8().get_data()];
    NSString *currencyStr = [NSString stringWithUTF8String:p_currency.utf8().get_data()];
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:eventTokenStr];
    [event setRevenue:p_amount currency:currencyStr];
    [Adjust trackEvent:event];
}

void AdjustGodotPlugin::track_app_store_subscription(String p_price, String p_currency, String p_transaction_id) {
    NSString *priceStr = [NSString stringWithUTF8String:p_price.utf8().get_data()];
    NSString *currencyStr = [NSString stringWithUTF8String:p_currency.utf8().get_data()];
    NSString *transactionIdStr = [NSString stringWithUTF8String:p_transaction_id.utf8().get_data()];
    
    NSDecimalNumber *decimalPrice = [NSDecimalNumber decimalNumberWithString:priceStr];
    ADJAppStoreSubscription *subscription = [[ADJAppStoreSubscription alloc] initWithPrice:decimalPrice
                                                                                  currency:currencyStr
                                                                             transactionId:transactionIdStr];
    [Adjust trackAppStoreSubscription:subscription];
}

void AdjustGodotPlugin::disable_third_party_sharing() {
    ADJThirdPartySharing *sharing = [[ADJThirdPartySharing alloc] initWithIsEnabled:@NO];
    [Adjust trackThirdPartySharing:sharing];
}

void AdjustGodotPlugin::gdpr_forget_me() {
    NSLog(@"AdjustGodotPlugin: gdpr_forget_me called. This action is irreversible.");
    [Adjust gdprForgetMe];
}

void AdjustGodotPlugin::set_url_strategy(PackedStringArray p_urls, bool p_use_subdomains, bool p_is_data_residency) {
    cached_urls = p_urls;
    cached_use_subdomains = p_use_subdomains;
    cached_is_data_residency = p_is_data_residency;
    has_cached_urls = true;
}

void AdjustGodotPlugin::request_tracking_authorization() {
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            NSLog(@"AdjustGodotPlugin: ATT authorization status: %lu", (unsigned long)status);
        }];
    }
}

Dictionary AdjustGodotPlugin::get_attribution() {
    return last_attribution;
}

void AdjustGodotPlugin::track_measurement_consent(bool p_enabled) {
    [Adjust trackMeasurementConsent:p_enabled ? YES : NO];
}

void AdjustGodotPlugin::track_ad_revenue(String p_source, double p_revenue, String p_currency) {
    NSString *sourceStr = [NSString stringWithUTF8String:p_source.utf8().get_data()];
    NSString *currencyStr = [NSString stringWithUTF8String:p_currency.utf8().get_data()];
    
    ADJAdRevenue *adRevenue = [[ADJAdRevenue alloc] initWithSource:sourceStr];
    if (adRevenue) {
        [adRevenue setRevenue:p_revenue currency:currencyStr];
        [Adjust trackAdRevenue:adRevenue];
    }
}

// Godot entry points
void init_adjust_plugin() {
    NSLog(@"AdjustGodotPlugin: Bridge init called");
    
    AdjustGodotPlugin *plugin = memnew(AdjustGodotPlugin);
    Engine::get_singleton()->add_singleton(Engine::Singleton("AdjustGodotPlugin", plugin));
}

void deinit_adjust_plugin() {
    NSLog(@"AdjustGodotPlugin: Bridge deinit called");
    
    AdjustGodotPlugin *plugin = AdjustGodotPlugin::get_singleton();
    if (plugin) {
        memdelete(plugin);
    }
}
