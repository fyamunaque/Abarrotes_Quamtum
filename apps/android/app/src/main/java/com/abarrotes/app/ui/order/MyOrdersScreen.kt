package com.abarrotes.app.ui.order

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.abarrotes.app.data.model.OrderSummary
import com.abarrotes.app.ui.components.LoadingState
import com.abarrotes.app.ui.components.MessageState
import com.abarrotes.app.ui.orderStatusLabel
import com.abarrotes.app.ui.theme.NeilsInk
import com.abarrotes.app.ui.theme.NeilsPrimaryTint
import com.abarrotes.app.ui.toSoles
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

// Hora de la tienda, no la del teléfono.
private val dateFormat = DateTimeFormatter
    .ofPattern("d MMM yyyy, HH:mm", Locale.forLanguageTag("es-PE"))
    .withZone(ZoneId.of("America/Lima"))

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyOrdersScreen(
    viewModel: MyOrdersViewModel,
    onBack: () -> Unit,
    onLoginClick: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mis pedidos") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Volver")
                    }
                },
                actions = {
                    if (state is MyOrdersState.Loaded || state is MyOrdersState.Error) {
                        IconButton(onClick = viewModel::refresh) {
                            Icon(Icons.Default.Refresh, contentDescription = "Actualizar")
                        }
                    }
                },
            )
        },
    ) { padding ->
        val modifier = Modifier.padding(padding)
        when (val current = state) {
            MyOrdersState.LoginRequired -> MessageState(
                message = "Inicia sesión para ver tus pedidos.",
                actionLabel = "Iniciar sesión",
                onAction = onLoginClick,
                modifier = modifier,
            )
            MyOrdersState.Loading -> LoadingState(modifier)
            is MyOrdersState.Error -> MessageState(
                message = current.message,
                actionLabel = "Reintentar",
                onAction = viewModel::refresh,
                modifier = modifier,
            )
            is MyOrdersState.Loaded -> if (current.orders.isEmpty()) {
                MessageState(message = "Todavía no tienes pedidos.", modifier = modifier)
            } else {
                LazyColumn(
                    modifier = modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(current.orders, key = { it.id }) { OrderCard(it) }
                }
            }
        }
    }
}

@Composable
private fun OrderCard(order: OrderSummary) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    "Pedido N.º ${order.id.take(8).uppercase()}",
                    style = MaterialTheme.typography.titleMedium,
                )
                StatusChip(order.status)
            }
            order.createdAt?.let {
                Text(
                    dateFormat.format(it),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            order.items.forEach { item ->
                Text("${item.quantity} × ${item.name}", style = MaterialTheme.typography.bodyMedium)
            }
            Text(
                "Entrega: ${order.deliveryAddress}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                "Total: ${order.total.toSoles()}",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

/** Mismos colores que el panel admin de la web (app/admin/pedidos). */
@Composable
private fun StatusChip(status: String) {
    val (background, content) = when (status) {
        "PENDING_CONFIRMATION" -> Color(0xFFFEF3C7) to Color(0xFF78350F)
        "CONFIRMED" -> Color(0xFFE0F2FE) to Color(0xFF0C4A6E)
        "OUT_FOR_DELIVERY" -> Color(0xFFEDE9FE) to Color(0xFF4C1D95)
        "DELIVERED" -> NeilsPrimaryTint to NeilsInk
        else -> Color(0xFFE3DBD0) to Color(0xFF493532) // ink/10 e ink/80 sobre crema
    }
    Surface(color = background, contentColor = content, shape = MaterialTheme.shapes.small) {
        Text(
            orderStatusLabel(status),
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
        )
    }
}
