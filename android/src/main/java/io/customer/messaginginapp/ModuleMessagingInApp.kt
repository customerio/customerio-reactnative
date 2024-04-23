package io.customer.messaginginapp

import android.app.Application
import androidx.annotation.VisibleForTesting
import io.customer.messaginginapp.di.gistProvider
import io.customer.messaginginapp.hook.ModuleInAppHookProvider
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOConfig
import io.customer.sdk.data.request.MetricEvent
import io.customer.sdk.di.CustomerIOComponent
import io.customer.sdk.hooks.HookModule
import io.customer.sdk.hooks.HooksManager
import io.customer.sdk.module.CustomerIOModule
import io.customer.sdk.repository.TrackRepository

class ModuleMessagingInApp
@VisibleForTesting
internal constructor(
    override val moduleConfig: MessagingInAppModuleConfig = MessagingInAppModuleConfig.default(),
    private val overrideDiGraph: CustomerIOComponent?
) : CustomerIOModule<MessagingInAppModuleConfig> {

    @JvmOverloads
    @Deprecated(
        "organizationId no longer required and will be removed in future",
        replaceWith = ReplaceWith("constructor(config: MessagingInAppModuleConfig)")
    )
    constructor(
        organizationId: String,
        config: MessagingInAppModuleConfig = MessagingInAppModuleConfig.default()
    ) : this(
        moduleConfig = config,
        overrideDiGraph = null
    )

    @JvmOverloads
    constructor(
        config: MessagingInAppModuleConfig = MessagingInAppModuleConfig.default()
    ) : this(
        moduleConfig = config,
        overrideDiGraph = null
    )

    override val moduleName: String = ModuleMessagingInApp.moduleName

    private val diGraph: CustomerIOComponent
        get() = overrideDiGraph ?: CustomerIO.instance().diGraph

    private val trackRepository: TrackRepository
        get() = diGraph.trackRepository

    private val identifier: String?
        get() = diGraph.sitePreferenceRepository.getIdentifier()

    private val hooksManager: HooksManager by lazy { diGraph.hooksManager }

    private val gistProvider by lazy { diGraph.gistProvider }

    private val logger by lazy { diGraph.logger }

    private val config: CustomerIOConfig
        get() = diGraph.sdkConfig

    companion object {
        const val moduleName: String = "MessagingInApp"
    }

    fun dismissMessage() {
        gistProvider.dismissMessage()
    }

    override fun initialize() {
        initializeGist(config)
        setupHooks()
        configureSdkModule(moduleConfig)
        setupGistCallbacks()
    }

    private fun configureSdkModule(moduleConfig: MessagingInAppModuleConfig) {
        moduleConfig.eventListener?.let { eventListener ->
            gistProvider.setListener(eventListener)
        }
    }

    private fun setupGistCallbacks() {
        gistProvider.subscribeToEvents(onMessageShown = { deliveryID ->
            logger.debug("in-app message shown $deliveryID")
            trackRepository.trackInAppMetric(
                deliveryID = deliveryID,
                event = MetricEvent.opened
            )
        }, onAction = { deliveryID: String, _: String, action: String, name: String ->
            logger.debug("in-app message clicked $deliveryID")
            trackRepository.trackInAppMetric(
                deliveryID = deliveryID,
                event = MetricEvent.clicked,
                metadata = mapOf("action_name" to name, "action_value" to action)
            )
        }, onError = { errorMessage ->
            logger.error("in-app message error occurred $errorMessage")
        })
    }

    private fun setupHooks() {
        hooksManager.add(
            module = HookModule.MessagingInApp,
            subscriber = ModuleInAppHookProvider()
        )
    }

    private fun initializeGist(config: CustomerIOConfig) {
        gistProvider.initProvider(
            application = diGraph.context.applicationContext as Application,
            siteId = config.siteId,
            region = config.region.code
        )

        // if identifier is already present, set the userToken again so in case if the customer was already identified and
        // module was added later on, we can notify gist about it.
        identifier?.let { gistProvider.setUserToken(it) }
    }
}
