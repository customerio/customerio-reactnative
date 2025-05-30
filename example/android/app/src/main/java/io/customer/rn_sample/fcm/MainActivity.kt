package io.customer.rn_sample.fcm

import android.os.Bundle
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate
import io.customer.rn_sample.fcm.R

/**
 * Subclassing to override getLaunchOptions
 * This is needed to pass the appName to be displayed
 * in the app footer
 */
class ReactDelegate public constructor(activity: ReactActivity, mainComponentName: String, fabricEnabled: Boolean = true) :
    DefaultReactActivityDelegate(activity, mainComponentName, fabricEnabled) {

    override fun getLaunchOptions(): Bundle {
        val options = Bundle()
        options.putString("appName", mainComponentName)
        return options
    }
}

class MainActivity : ReactActivity() {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "React Native Android"

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate =
      ReactDelegate(this, mainComponentName, fabricEnabled)

  //react-native-screens override
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(null);
  }
}
