package com.abarrotes.app

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
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
        // La app es siempre clara (fondo crema): íconos oscuros en las barras del sistema
        // aunque el teléfono esté en modo oscuro.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(CREAM_SCRIM, CREAM_SCRIM),
        )
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

    private companion object {
        /** Crema de la marca (#F9F3E7) al 90 %: fondo de la barra de navegación de 3 botones. */
        const val CREAM_SCRIM = 0xE6F9F3E7.toInt()
    }
}
