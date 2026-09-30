package com.abarrotes.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.abarrotes.app.ui.navigation.AbarrotesNavHost
import com.abarrotes.app.ui.theme.AbarrotesTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = (application as AbarrotesApplication).container
        setContent {
            AbarrotesTheme {
                AbarrotesNavHost(container)
            }
        }
    }
}
