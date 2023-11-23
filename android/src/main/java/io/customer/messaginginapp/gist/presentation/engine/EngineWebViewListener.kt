package io.customer.messaginginapp.gist.presentation.engine

interface EngineWebViewListener {
    fun bootstrapped()
    fun tap(name: String, action: String, system: Boolean)
    fun routeChanged(newRoute: String)
    fun routeError(route: String)
    fun routeLoaded(route: String)
    fun sizeChanged(width: Double, height: Double)
    fun error()
}
