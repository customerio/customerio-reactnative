package io.customer.reactnative.sdk.extension

internal fun String.takeIfNotBlank(): String? = takeIf { it.isNotBlank() }
