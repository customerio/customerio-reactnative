package io.customer.messaginginapp.hook

import io.customer.messaginginapp.di.gistProvider
import io.customer.messaginginapp.provider.InAppMessagesProvider
import io.customer.sdk.CustomerIO
import io.customer.sdk.di.CustomerIOComponent
import io.customer.sdk.hooks.ModuleHook
import io.customer.sdk.hooks.ModuleHookProvider

internal class ModuleInAppHookProvider : ModuleHookProvider() {

    private val diGraph: CustomerIOComponent
        get() = CustomerIO.instance().diGraph

    private val gistProvider: InAppMessagesProvider
        get() = diGraph.gistProvider

    override fun profileIdentifiedHook(hook: ModuleHook.ProfileIdentifiedHook) {
        gistProvider.setUserToken(hook.identifier)
    }

    override fun screenTrackedHook(hook: ModuleHook.ScreenTrackedHook) {
        gistProvider.setCurrentRoute(hook.screen)
    }

    override fun beforeProfileStoppedBeingIdentified(hook: ModuleHook.BeforeProfileStoppedBeingIdentified) {
        gistProvider.clearUserToken()
    }
}
