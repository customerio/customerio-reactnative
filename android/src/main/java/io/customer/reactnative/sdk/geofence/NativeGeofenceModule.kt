package io.customer.reactnative.sdk.geofence

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import io.customer.geofence.GeofenceLocationMode
import io.customer.geofence.GeofenceModuleConfig
import io.customer.geofence.ModuleGeofence
import io.customer.reactnative.sdk.NativeCustomerIOGeofenceSpec
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger

/**
 * React Native module implementation for Customer.io Geofence Native SDK
 * using TurboModules with new architecture.
 *
 * The reference to [ModuleGeofence] is isolated in this file so the geofence dependency is
 * only loaded when the module is enabled and bundled. Geofence depends on the location
 * module, which the caller registers alongside it.
 */
@ReactModule(name = NativeGeofenceModule.NAME)
class NativeGeofenceModule(
    private val reactContext: ReactApplicationContext,
) : NativeCustomerIOGeofenceSpec(reactContext) {
    private val logger: Logger
        get() = SDKComponent.logger

    private fun getModuleGeofence() = runCatching {
        ModuleGeofence.instance()
    }.onFailure {
        logger.error("Geofence module is not initialized. Ensure geofence config is provided during SDK initialization.")
    }.getOrNull()

    override fun refreshFromCurrentLocation() {
        getModuleGeofence()?.refreshFromCurrentLocation()
    }

    companion object {
        const val NAME = "NativeCustomerIOGeofence"

        /**
         * Adds the geofence module to the native Android SDK based on the configuration
         * provided by the customer app.
         *
         * @param builder instance of CustomerIOBuilder to add the geofence module.
         * @param config configuration provided by the customer app for the geofence module.
         */
        internal fun addNativeModuleFromConfig(
            builder: CustomerIOBuilder,
            config: Map<String, Any>
        ) {
            val locationModeValue = config.getTypedValue<String>("locationMode")
            // Uppercase before matching so casing can't diverge from iOS (which uppercases too);
            // enumValueOf is case-sensitive. Unknown values fall back to the SDK default.
            val locationMode = locationModeValue?.let { value ->
                runCatching { enumValueOf<GeofenceLocationMode>(value.uppercase()) }.getOrNull()
            }

            val configBuilder = GeofenceModuleConfig.Builder()
            locationMode?.let { configBuilder.setLocationMode(it) }
            builder.addCustomerIOModule(ModuleGeofence(configBuilder.build()))
        }
    }
}
