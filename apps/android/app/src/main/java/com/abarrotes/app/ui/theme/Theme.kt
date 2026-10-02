package com.abarrotes.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Paleta de Neil's Food Services: los mismos tokens que la web (apps/web/src/app/globals.css).
val NeilsPrimary = Color(0xFFE8652F)
val NeilsPrimaryDark = Color(0xFFB54F25)
val NeilsAccent = Color(0xFFA1241B)
val NeilsCream = Color(0xFFF9F3E7)
val NeilsInk = Color(0xFF1D0605)
val NeilsPrimaryTint = Color(0xFFF6D9C6)

/**
 * Material usa "primary" a la vez como fondo de botón y como color de texto (precios,
 * TextButton, etiqueta del campo con foco). El naranja de marca sobre crema da 3,0:1, así
 * que primary es primary-dark (4,6:1 sobre crema; blanco encima, 5,1:1). El naranja va en
 * secondaryContainer: lo usan FilledTonalButton ("Agregar") con texto tinta (5,9:1), igual
 * que en la web. inverseSurface (tinta) marca lo seleccionado, como los chips de la web.
 */
private val NeilsColors = lightColorScheme(
    primary = NeilsPrimaryDark,
    onPrimary = Color.White,
    primaryContainer = NeilsPrimaryTint,
    onPrimaryContainer = NeilsInk,
    secondary = NeilsAccent,
    onSecondary = NeilsCream,
    secondaryContainer = NeilsPrimary,
    onSecondaryContainer = NeilsInk,
    background = NeilsCream,
    onBackground = NeilsInk,
    surface = NeilsCream,
    onSurface = NeilsInk,
    // Neutros: tinta mezclada con crema (como ink/70, ink/50 e ink/15 en la web).
    surfaceVariant = Color(0xFFEFE5D6),
    onSurfaceVariant = Color(0xFF5F4D49),
    outline = Color(0xFF8B7C76),
    outlineVariant = Color(0xFFD8CFC5),
    surfaceContainerLowest = Color(0xFFFFFCF6),
    surfaceContainerLow = Color(0xFFF5EDDF),
    surfaceContainer = Color(0xFFF1E8D9),
    surfaceContainerHigh = Color(0xFFECE2D1),
    surfaceContainerHighest = Color(0xFFE7DCCA),
    inverseSurface = NeilsInk,
    inverseOnSurface = NeilsCream,
)

// Como la web, la app usa siempre la paleta clara de la marca (fondo crema), sin modo
// oscuro ni colores dinámicos de Material You: la tienda se ve igual en todos los teléfonos.
@Composable
fun AbarrotesTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = NeilsColors, content = content)
}
