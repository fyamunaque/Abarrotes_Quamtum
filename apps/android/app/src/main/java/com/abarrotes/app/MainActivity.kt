package com.abarrotes.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import com.abarrotes.app.ui.navigation.AbarrotesNavHost
import com.abarrotes.app.ui.theme.AbarrotesTheme

class MainActivity : ComponentActivity() {
    // Si se rechaza, la app abre igual: el catálogo muestra el error de conexión con "Reintentar".
    private val localNetworkPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { showApp() }

    private var appShown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // Se pide antes de mostrar la UI para que el catálogo no cargue sin red. Si la Activity
        // se recrea con el diálogo abierto, el resultado llega igual al callback.
        if (savedInstanceState == null && needsLocalNetworkPermission()) {
            localNetworkPermission.launch(Manifest.permission.ACCESS_LOCAL_NETWORK)
        } else {
            showApp()
        }
    }

    private fun showApp() {
        if (appShown) return
        appShown = true
        val container = (application as AbarrotesApplication).container
        setContent {
            AbarrotesTheme {
                AbarrotesNavHost(container)
            }
        }
    }

    /** Android 17+ exige permiso para la red local; solo la build debug apunta a una API local. */
    private fun needsLocalNetworkPermission() =
        BuildConfig.DEBUG &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.CINNAMON_BUN &&
            checkSelfPermission(Manifest.permission.ACCESS_LOCAL_NETWORK) != PackageManager.PERMISSION_GRANTED
}
