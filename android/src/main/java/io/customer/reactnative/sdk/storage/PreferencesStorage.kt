package io.customer.reactnative.sdk.storage

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import io.customer.reactnative.sdk.constant.Keys

class PreferencesStorage(context: Context) {
    private val preferenceFileKeyPrefix = "${context.packageName}.cio.rn"
    private val preferenceFileKey = "${preferenceFileKeyPrefix}.PREFERENCE_FILE_KEY"
    private val sharedPref: SharedPreferences

    private val environmentKeys = with(Keys.Environment) {
        arrayOf(SITE_ID, API_KEY, REGION, ORGANIZATION_ID)
    }
    private val configKeys = with(Keys.Config) {
        arrayOf(
            LOG_LEVEL,
            TRACKING_API_URL,
            AUTO_TRACK_DEVICE_ATTRIBUTES,
            AUTO_TRACK_PUSH_EVENTS,
            BACKGROUND_QUEUE_MIN_NUMBER_OF_TASKS,
            BACKGROUND_QUEUE_SECONDS_DELAY,
        )
    }
    private val packageConfigKeys = with(Keys.PackageConfig) {
        arrayOf(SOURCE_SDK, SOURCE_SDK_VERSION)
    }

    init {
        sharedPref = context.getSharedPreferences(
            preferenceFileKey, Context.MODE_PRIVATE,
        )
    }

    fun saveSettings(
        environment: Map<String, Any?>,
        configuration: Map<String, Any?>?,
        packageConfig: Map<String, Any?>?,
    ) = with(sharedPref.edit()) {
        for (key in environmentKeys) {
            putString(key, environment[key]?.toString()?.encodeToBase64())
        }
        if (configuration != null) {
            for (key in configKeys) {
                putString(key, configuration[key]?.toString()?.encodeToBase64())
            }
        }
        if (packageConfig != null) {
            for (key in packageConfigKeys) {
                putString(key, packageConfig[key]?.toString()?.encodeToBase64())
            }
        }
        apply()
    }

    private fun loadSettings(
        keys: Array<String>,
        typeConverter: ((String, String?) -> Any?)? = null,
    ): Map<String, Any?> {
        val map = hashMapOf<String, Any?>()
        with(sharedPref) {
            for (key in keys) {
                map[key] = getString(key, null)?.decodeFromBase64().let { property ->
                    typeConverter?.invoke(key, property) ?: property
                }
            }
        }
        return map
    }

    fun loadPackageConfigurations() = loadSettings(
        keys = packageConfigKeys.plus(Keys.PackageConfig.SOURCE_SDK_VERSION_COMPAT),
    )

    fun loadEnvironmentSettings() = loadSettings(environmentKeys)
    fun loadConfigurationSettings() = loadSettings(configKeys) { key, value ->
        with(Keys.Config) {
            return@with when (key) {
                LOG_LEVEL,
                BACKGROUND_QUEUE_MIN_NUMBER_OF_TASKS,
                BACKGROUND_QUEUE_SECONDS_DELAY,
                -> value?.toDoubleOrNull()
                AUTO_TRACK_DEVICE_ATTRIBUTES,
                AUTO_TRACK_PUSH_EVENTS,
                -> value?.toBooleanStrictOrNull()
                TRACKING_API_URL -> value
                else -> value
            }
        }
    }

    companion object {
        private fun String.encodeToBase64(): String {
            return Base64.encodeToString(toByteArray(Charsets.UTF_8), Base64.NO_WRAP)
        }

        private fun String.decodeFromBase64(): String {
            return Base64.decode(this, Base64.NO_WRAP).toString(Charsets.UTF_8)
        }
    }
}
