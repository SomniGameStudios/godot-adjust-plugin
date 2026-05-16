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
#include "core/config/engine.h"
#include "core/object/class_db.h"

// Forward declarations of Swift functions (implemented in Swift)
#ifdef __cplusplus
extern "C" {
#endif
void swift_init_adjust_plugin();
void swift_deinit_adjust_plugin();
void swift_adjust_initialize(const char* app_token, bool is_sandbox, int att_wait_interval);
void swift_adjust_track_event(const char* event_token);
void swift_adjust_track_event_with_revenue(const char* event_token, double amount, const char* currency);
void swift_adjust_track_app_store_subscription(const char* price, const char* currency, const char* transaction_id);
void swift_adjust_disable_third_party_sharing();
void swift_adjust_gdpr_forget_me();
void swift_adjust_set_url_strategy(const char** urls, int url_count, bool use_subdomains, bool is_data_residency);
#ifdef __cplusplus
}
#endif

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
    void initialize(String p_app_token, bool p_is_sandbox, int p_att_wait_interval) {
        swift_adjust_initialize(p_app_token.utf8().get_data(), p_is_sandbox, p_att_wait_interval);
    }

    void track_event(String p_event_token) {
        swift_adjust_track_event(p_event_token.utf8().get_data());
    }

    void track_event_with_revenue(String p_event_token, double p_amount, String p_currency) {
        swift_adjust_track_event_with_revenue(p_event_token.utf8().get_data(), p_amount, p_currency.utf8().get_data());
    }

    void track_app_store_subscription(String p_price, String p_currency, String p_transaction_id) {
        swift_adjust_track_app_store_subscription(p_price.utf8().get_data(), p_currency.utf8().get_data(), p_transaction_id.utf8().get_data());
    }

    void disable_third_party_sharing() {
        swift_adjust_disable_third_party_sharing();
    }

    void gdpr_forget_me() {
        swift_adjust_gdpr_forget_me();
    }

    void set_url_strategy(PackedStringArray p_urls, bool p_use_subdomains, bool p_is_data_residency) {
        int count = p_urls.size();
        const char **urls = (const char **)malloc(sizeof(const char *) * count);
        for (int i = 0; i < count; i++) {
            urls[i] = p_urls[i].utf8().get_data();
        }
        swift_adjust_set_url_strategy(urls, count, p_use_subdomains, p_is_data_residency);
        free(urls);
    }

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

// Godot entry points (MUST BE C++ LINKAGE)
void init_adjust_plugin() {
    NSLog(@"AdjustGodotPlugin: Bridge init called");
    
    AdjustGodotPlugin *plugin = memnew(AdjustGodotPlugin);
    Engine::get_singleton()->add_singleton(Engine::Singleton("AdjustGodotPlugin", plugin));
    
    swift_init_adjust_plugin();
}

void deinit_adjust_plugin() {
    NSLog(@"AdjustGodotPlugin: Bridge deinit called");
    
    AdjustGodotPlugin *plugin = AdjustGodotPlugin::get_singleton();
    if (plugin) {
        memdelete(plugin);
    }
    
    swift_deinit_adjust_plugin();
}
