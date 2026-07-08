# iOS App Tracking Transparency (ATT)

On iOS, the IDFA (which Adjust uses for install attribution) is only readable after the
user has resolved the system **App Tracking Transparency** prompt. There are two ways an
app can get that prompt shown. This plugin supports both. Pick one and do not mix them.

## Model A — the plugin shows the ATT prompt

The app asks the plugin to display the ATT dialog itself.

1. Set `adjust/config/att_wait_interval` (seconds, `0`–`360`) so the SDK waits for the
   ATT decision before sending install data.
2. Assign the `att_status_received` callback **before** you request authorization.
3. Call `request_tracking_authorization()`. The plugin shows the system dialog and
   delivers the resulting status (`0` not determined, `1` restricted, `2` denied,
   `3` authorized) to `att_status_received`.

```gdscript
func _ready() -> void:
    AdjustPlugin.att_status_received = _on_att_status
    AdjustPlugin.initialize()                   # reads Project Settings
    AdjustPlugin.request_tracking_authorization()

func _on_att_status(status: int) -> void:
    print("ATT status: ", status)
```

Use Model A when your app owns the ATT prompt directly.

## Model B — a consent SDK shows the ATT prompt

If your app already uses a separate consent SDK (for example Google AdMob UMP) that is
configured to present the ATT explainer/prompt for you, **do not** call
`request_tracking_authorization()`. The plugin only needs to wait for the OS-level ATT
decision and then read the unlocked IDFA:

1. Let your consent SDK present the ATT prompt as part of its own flow.
2. Set `adjust/config/att_wait_interval` (seconds, `0`–`360`) so the SDK waits for the
   ATT decision before sending install data. Maps to `ADJConfig.attConsentWaitingInterval`.
3. Call `AdjustPlugin.initialize()`. Do **not** call `request_tracking_authorization()`.

```gdscript
func _ready() -> void:
    # your consent SDK (e.g. AdMob UMP) presents ATT separately
    AdjustPlugin.initialize()  # att_wait_interval read from Project Settings
    # do NOT call request_tracking_authorization() in this model
```

Use Model B when a consent SDK, not your app, owns the ATT prompt. This is the common
setup for apps that gate tracking behind a GDPR/consent flow: calling
`request_tracking_authorization()` yourself could show the ATT prompt to a user who has
already declined tracking in that flow.

### Reading the ATT decision under Model B

In Model B the plugin never fires `att_status_received` (that callback fires only as the
result of `request_tracking_authorization()`, i.e. Model A). If you need the ATT decision
for your own analytics under Model B, use the non-prompting
[`get_att_status()`](gdscript_api.md#get_att_status) getter, which reads the current
status without ever showing a dialog:

```gdscript
var status := AdjustPlugin.get_att_status()   # 0..3, or -1 if unavailable
if status >= 0 and status != 0:               # skip "unavailable" and "not determined"
    var authorized := status == 3
    # forward the decision to your own analytics
```
