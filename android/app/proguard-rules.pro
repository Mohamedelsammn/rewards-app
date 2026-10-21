# WorkManager 2.7.0 (pulled transitively by Google Mobile Ads) and Room 2.2.5
# instantiate these generated/registered types reflectively. Their shipped keep
# rules do not retain the no-argument constructors under the current R8 full-mode
# release build; the release DEX was confirmed to have stripped these constructors.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}

-keep class com.google.firebase.installations.FirebaseInstallationsKtxRegistrar {
    public <init>();
}

-keep class com.google.firebase.messaging.FirebaseMessagingKtxRegistrar {
    public <init>();
}
