package com.abarrotes.app

import android.app.Application
import com.abarrotes.app.di.AppContainer

class AbarrotesApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
