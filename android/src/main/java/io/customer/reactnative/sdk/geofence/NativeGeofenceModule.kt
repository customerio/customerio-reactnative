package io.customer.reactnative.sdk.geofence

import io.customer.geofence.GeofenceModuleConfig
import io.customer.geofence.ModuleGeofence
import io.customer.sdk.CustomerIOBuilder

/**
 * Registers the optional geofence module with the native Android SDK.
 *
 * Geofence has no app-facing methods — it runs automatically once registered — so this is
 * not a TurboModule. The reference to [ModuleGeofence] is isolated here so the geofence
 * dependency is only loaded when the module is enabled and bundled. Geofence depends on the
 * location module, which the caller registers alongside it.
 */
internal object NativeGeofenceModule {
    /**
     * Adds the geofence module to the native Android SDK.
     *
     * @param builder instance of CustomerIOBuilder to add the geofence module.
     * @param config configuration provided by the customer app for the geofence module.
     */
    fun addNativeModuleFromConfig(
        builder: CustomerIOBuilder,
        @Suppress("UNUSED_PARAMETER") config: Map<String, Any>
    ) {
        builder.addCustomerIOModule(
            ModuleGeofence(GeofenceModuleConfig.Builder().build())
        )
    }
}
