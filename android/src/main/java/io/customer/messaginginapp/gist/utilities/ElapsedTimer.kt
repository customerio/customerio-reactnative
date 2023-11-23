package io.customer.messaginginapp.gist.utilities

import android.util.Log
import io.customer.messaginginapp.gist.presentation.GIST_TAG

class ElapsedTimer {
    private var title: String = ""
    private var startTime: Long = 0

    fun start(title: String) {
        this.title = title
        this.startTime = System.currentTimeMillis()
    }

    fun end() {
        if (startTime > 0) {
            val timeElapsed = (System.currentTimeMillis() - startTime) / 1000.0
            Log.d(GIST_TAG, "$title timer elapsed in $timeElapsed seconds")
            startTime = 0
        }
    }
}
