package com.customerioreactnative

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import android.util.Log 

class CustomerioReactnativeModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "CustomerioReactnative"
    }

    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    fun multiply(a: Int, b: Int, promise: Promise) {
    
      promise.resolve(a * b)
    
    }

    @ReactMethod
    fun initialize(a: String, b: String, region: String, promise: Promise) {
      Log.i("hey","Hello world")
      promise.resolve(true)
    }

    @ReactMethod
    fun testMethod(promise : Promise) {
      promise.resolve("I am called")
    }
    
}
