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
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>
#import <AdjustSdk/ADJEvent.h>
#import <AdjustSdk/ADJAttribution.h>
#import <AdjustSdk/ADJThirdPartySharing.h>
#import <AdjustSdk/ADJAppStoreSubscription.h>
#import <AdjustSdk/ADJLogger.h>
#include "core/config/engine.h"
#include "core/object/class_db.h"

class AdjustGodotPlugin : public Object {
    GDCLASS(AdjustGodotPlugin, Object);

    static AdjustGodotPlugin *instance;

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("initialize", "app_token", "is_sandbox", "att_wait_interval"), &AdjustGodotPlugin::initialize);
        ClassDB::bind_method(D_METHOD("track_event", "event_token"), &AdjustGodotPlugin::track_event);
        ClassDB::bind_method(D_METHOD("track_event_with_revenue", "event_token", "amount", "currency"), &AdjustGodotPlugin::track_event_with_revenue);
        ClassDB::bind_method(D_METHOD("track_app_store_subscription", "price", "currency", "transaction_id"), &AdjustGodotPlugin::track_app_store_subscription);
        ClassDB::bind_method(D_METHOD("disable_third_party_sharing"), &AdjustGodotPlugin::disable_third_party_sharing);
        ClassDB::bind_method(D_METHOD("gdpr_forget_me"), &AdjustGodotPlugin::gdpr_forget_me);
        ClassDB::bind_method(D_METHOD("set_url_strategy", "urls", "use_subdomains", "is_data_residency"), &AdjustGodotPlugin::set_url_strategy);
        
        ADD_SIGNAL(MethodInfo("attribution_changed", PropertyInfo(Variant::DICTIONARY, "data")));
        ADD_SIGNAL(MethodInfo("initialization_completed"));
    }

public:
    void initialize(String p_app_token, bool p_is_sandbox, int p_att_wait_interval);
    void track_event(String p_event_token);
    void track_event_with_revenue(String p_event_token, double p_amount, String p_currency);
    void track_app_store_subscription(String p_price, String p_currency, String p_transaction_id);
    void disable_third_party_sharing();
    void gdpr_forget_me();
    void set_url_strategy(PackedStringArray p_urls, bool p_use_subdomains, bool p_is_data_residency);

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
    AdjustGodotPlugin *plugin = AdjustGodotPlugin::get_singleton();
    if (plugin) {
        Dictionary data;
        data["tracker_token"] = attribution.trackerToken ? String::utf8([attribution.trackerToken UTF8String]) : "";
        data["tracker_name"] = attribution.trackerName ? String::utf8([attribution.trackerName UTF8String]) : "";
        data["network"] = attribution.network ? String::utf8([attribution.network UTF8String]) : "";
        data["campaign"] = attribution.campaign ? String::utf8([attribution.campaign UTF8String]) : "";
        data["adgroup"] = attribution.adgroup ? String::utf8([attribution.adgroup UTF8String]) : "";
        data["creative"] = attribution.creative ? String::utf8([attribution.creative UTF8String]) : "";
        data["click_label"] = attribution.clickLabel ? String::utf8([attribution.clickLabel UTF8String]) : "";
        plugin->emit_signal("attribution_changed", data);
    }
}

@end

void AdjustGodotPlugin::initialize(String p_app_token, bool p_is_sandbox, int p_att_wait_interval) {
    NSString *appTokenStr = [NSString stringWithUTF8String:p_app_token.utf8().get_data()];
    NSString *environment = p_is_sandbox ? ADJEnvironmentSandbox : ADJEnvironmentProduction;
    
    ADJConfig *config = [[ADJConfig alloc] initWithAppToken:appTokenStr environment:environment];
    if (config == nil) {
        NSLog(@"AdjustGodotPlugin: Failed to create ADJConfig");
        return;
    }
    
    [config setLogLevel:p_is_sandbox ? ADJLogLevelVerbose : ADJLogLevelInfo];
    [config setAttConsentWaitingInterval:(NSUInteger)p_att_wait_interval];
    [config setDelegate:[AdjustGodotDelegate sharedInstance]];
    
    [Adjust initSdk:config];
    
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
    NSLog(@"AdjustGodotPlugin: set_url_strategy called. Note: In v5 this must be set on config before initialization.");
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
