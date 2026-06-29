# Android

## `AD_ID` permission (Google Advertising ID)

The Adjust SDK declares the `com.google.android.gms.permission.AD_ID` permission, which lets it read the Google Advertising ID — Adjust's primary signal for install attribution on Android. **This plugin keeps that permission by default**, so attribution works out of the box for general-audience apps.

!!! warning "Remove `AD_ID` for child-directed or non-Play apps"

    Google Play's Families policy (and COPPA) prohibit collecting the Advertising ID when an app's target audience includes children. If your app is child-directed, or you distribute outside the Google Play Store, you must remove the permission in **your own app's** `AndroidManifest.xml`:

    ```xml
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"/>
    ```

    Add it to your app-level manifest (the highest-priority manifest in the merge) so it removes the permission the SDK contributes. The `tools` namespace must be declared on the `<manifest>` root:

    ```xml
    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:tools="http://schemas.android.com/tools">
    ```

Keeping the permission gives the most accurate attribution and is the correct default for general-audience apps. Removing it is required only for the child-directed or non-Play cases above — the trigger is your Google Play **target-audience** declaration, not the app's content rating.
