package com.abarrotes.app.ui.cart

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.abarrotes.app.data.model.OrderConfirmation
import com.abarrotes.app.data.session.Session
import com.abarrotes.app.ui.components.MessageState
import com.abarrotes.app.ui.components.ProductImage
import com.abarrotes.app.ui.components.QuantityStepper
import com.abarrotes.app.ui.toSoles

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(
    viewModel: CartViewModel,
    onBack: () -> Unit,
    onLoginRequired: () -> Unit,
    onOrderPlaced: (OrderConfirmation) -> Unit,
) {
    val cart by viewModel.cart.collectAsStateWithLifecycle()
    val checkout by viewModel.checkout.collectAsStateWithLifecycle()
    val session by viewModel.session.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(checkout) {
        when (val result = checkout) {
            is CheckoutState.Success -> {
                onOrderPlaced(result.order)
                viewModel.consumeCheckoutResult()
            }
            is CheckoutState.Error -> {
                viewModel.consumeCheckoutResult()
                snackbarHostState.showSnackbar(result.message)
            }
            else -> Unit
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Tu carrito") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Volver")
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        if (cart.isEmpty()) {
            MessageState(
                message = "Tu carrito está vacío.",
                actionLabel = "Ver productos",
                onAction = onBack,
                modifier = Modifier.padding(padding),
            )
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .imePadding(),
        ) {
            items(cart.lines, key = { it.product.id }) { line ->
                CartLineRow(
                    line = line,
                    onDecrease = { viewModel.decrease(line.product) },
                    onIncrease = { viewModel.add(line.product) },
                    onRemove = { viewModel.remove(line.product.id) },
                )
                HorizontalDivider()
            }
            item {
                CheckoutSection(
                    total = cart.total.toSoles(),
                    session = session,
                    isSubmitting = checkout == CheckoutState.Submitting,
                    onLoginRequired = onLoginRequired,
                    onLogout = viewModel::logout,
                    onPlaceOrder = viewModel::placeOrder,
                )
            }
        }
    }
}

@Composable
private fun CartLineRow(
    line: CartLine,
    onDecrease: () -> Unit,
    onIncrease: () -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProductImage(line.product.imageUrl, Modifier.size(56.dp))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(
                line.product.name,
                style = MaterialTheme.typography.titleSmall,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                "${line.product.price.toSoles()} c/u",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(line.subtotal.toSoles(), style = MaterialTheme.typography.titleSmall)
        }
        QuantityStepper(
            quantity = line.quantity,
            onDecrease = onDecrease,
            onIncrease = onIncrease,
            canIncrease = line.quantity < Cart.maxQuantityFor(line.product),
        )
        IconButton(onClick = onRemove) {
            Icon(Icons.Default.Delete, contentDescription = "Quitar ${line.product.name}")
        }
    }
}

@Composable
private fun CheckoutSection(
    total: String,
    session: Session?,
    isSubmitting: Boolean,
    onLoginRequired: () -> Unit,
    onLogout: () -> Unit,
    onPlaceOrder: (String) -> Unit,
) {
    // Se reinicia con la dirección guardada del usuario cuando inicia sesión.
    var address by rememberSaveable(session?.userAddress) {
        mutableStateOf(session?.userAddress.orEmpty())
    }

    Column(
        modifier = Modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Total", style = MaterialTheme.typography.titleLarge)
            Text(total, style = MaterialTheme.typography.titleLarge)
        }
        Text(
            "El total final lo confirma la tienda con los precios vigentes.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        if (session == null) {
            Button(onClick = onLoginRequired, modifier = Modifier.fillMaxWidth()) {
                Text("Inicia sesión para pedir")
            }
            return@Column
        }

        OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text("Dirección de entrega") },
            modifier = Modifier.fillMaxWidth(),
        )
        Button(
            onClick = { onPlaceOrder(address) },
            enabled = address.isNotBlank() && !isSubmitting,
            modifier = Modifier.fillMaxWidth(),
        ) {
            if (isSubmitting) {
                CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
            } else {
                Text("Generar pedido")
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Pedido a nombre de ${session.userName}",
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.weight(1f),
            )
            TextButton(onClick = onLogout) { Text("Cerrar sesión") }
        }
        Spacer(Modifier.height(8.dp))
    }
}
