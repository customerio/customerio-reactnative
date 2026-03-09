package io.customer.reactnative.sdk.location

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import io.customer.location.LocationModuleConfig
import io.customer.location.LocationTrackingMode
import io.customer.location.ModuleLocation
import io.customer.reactnative.sdk.NativeCustomerIOLocationSpec
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger

/**
 * React Native module implementation for Customer.io Location Native SDK
 * using TurboModules with new architecture.
 */
@ReactModule(name = NativeLocationModule.NAME)
class NativeLocationModule(
    private val reactContext: ReactApplicationContext,
) : NativeCustomerIOLocationSpec(reactContext) {
    private val logger: Logger
        get() = SDKComponent.logger

    private fun getLocationServices() = runCatching {
        ModuleLocation.instance().locationServices
    }.onFailure {
        logger.error("Location module is not initialized. Ensure location config is provided during SDK initialization.")
    }.getOrNull()

    override fun setLastKnownLocation(latitude: Double, longitude: Double) {
        getLocationServices()?.setLastKnownLocation(latitude, longitude)
    }

    override fun requestLocationUpdate() {
        getLocationServices()?.requestLocationUpdate()
    }

    companion object {
        const val NAME = "NativeCustomerIOLocation"

        /**
         * Adds location module to native Android SDK based on the configuration provided by
         * customer app.
         *
         * @param builder instance of CustomerIOBuilder to add location module.
         * @param config configuration provided by customer app for location module.
         */
        internal fun addNativeModuleFromConfig(
            builder: CustomerIOBuilder,
            config: Map<String, Any>
        ) {
            val trackingModeValue = config.getTypedValue<String>("trackingMode")
            val trackingMode = trackingModeValue?.let { value ->
                runCatching { enumValueOf<LocationTrackingMode>(value) }.getOrNull()
            } ?: LocationTrackingMode.MANUAL

            val module = ModuleLocation(
                LocationModuleConfig.Builder()
                    .setLocationTrackingMode(trackingMode)
                    .build()
            )
            builder.addCustomerIOModule(module)
        }
    }
}
