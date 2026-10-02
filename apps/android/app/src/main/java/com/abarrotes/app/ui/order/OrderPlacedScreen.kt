package com.abarrotes.app.ui.order

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.abarrotes.app.ui.orderStatusLabel
import com.abarrotes.app.ui.toSoles
import java.math.BigDecimal

@Composable
fun OrderPlacedScreen(
    orderId: String,
    total: BigDecimal,
    status: String,
    onContinue: () -> Unit,
    onMyOrders: () -> Unit,
) {
    Scaffold { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(
                Icons.Default.CheckCircle,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(72.dp),
            )
            Spacer(Modifier.height(16.dp))
            Text("¡Pedido recibido!", style = MaterialTheme.typography.headlineSmall)
            Spacer(Modifier.height(8.dp))
            // Número corto para dictarlo por teléfono; el id completo queda en el dashboard.
            Text("Pedido N.º ${orderId.take(8).uppercase()}", style = MaterialTheme.typography.titleMedium)
            Text("Total: ${total.toSoles()}", style = MaterialTheme.typography.titleMedium)
            Text(
                "Estado: ${orderStatusLabel(status)}",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "La tienda confirmará tu pedido antes de enviarlo.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(24.dp))
            Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) {
                Text("Seguir comprando")
            }
            Spacer(Modifier.height(8.dp))
            OutlinedButton(onClick = onMyOrders, modifier = Modifier.fillMaxWidth()) {
                Text("Ver mis pedidos")
            }
        }
    }
}
