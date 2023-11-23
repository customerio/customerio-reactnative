package io.customer.messaginginapp

import io.customer.messaginginapp.type.InAppEventListener
import io.customer.sdk.module.CustomerIOModuleConfig

/**
 * In app messaging module configurations that can be used to customize app
 * experience based on the provided configurations
 */
class MessagingInAppModuleConfig private constructor(
    val eventListener: InAppEventListener?
) : CustomerIOModuleConfig {
    class Builder : CustomerIOModuleConfig.Builder<MessagingInAppModuleConfig> {
        private var eventListener: InAppEventListener? = null

        fun setEventListener(eventListener: InAppEventListener): Builder {
            this.eventListener = eventListener
            return this
        }

        override fun build(): MessagingInAppModuleConfig {
            return MessagingInAppModuleConfig(
                eventListener = eventListener
            )
        }
    }

    companion object {
        internal fun default(): MessagingInAppModuleConfig = Builder().build()
    }
}
