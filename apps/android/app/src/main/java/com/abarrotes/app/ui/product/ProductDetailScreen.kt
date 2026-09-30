package com.abarrotes.app.ui.product

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.BottomAppBar
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.abarrotes.app.data.model.Product
import com.abarrotes.app.ui.cart.Cart
import com.abarrotes.app.ui.cart.CartViewModel
import com.abarrotes.app.ui.components.CartActionButton
import com.abarrotes.app.ui.components.LoadingState
import com.abarrotes.app.ui.components.MessageState
import com.abarrotes.app.ui.components.ProductImage
import com.abarrotes.app.ui.components.QuantityStepper
import com.abarrotes.app.ui.toSoles

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    viewModel: ProductDetailViewModel,
    cartViewModel: CartViewModel,
    onBack: () -> Unit,
    onCartClick: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val cart by cartViewModel.cart.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Detalle") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Volver")
                    }
                },
                actions = { CartActionButton(cart.itemCount, onCartClick) },
            )
        },
        bottomBar = {
            (state as? ProductDetailState.Loaded)?.product?.let { product ->
                AddToCartBar(
                    product = product,
                    quantityInCart = cart.quantityOf(product.id),
                    onAdd = { cartViewModel.add(product) },
                    onDecrease = { cartViewModel.decrease(product) },
                    onCartClick = onCartClick,
                )
            }
        },
    ) { padding ->
        when (val current = state) {
            ProductDetailState.Loading -> LoadingState(Modifier.padding(padding))
            is ProductDetailState.Error -> MessageState(
                message = current.message,
                actionLabel = "Reintentar",
                onAction = viewModel::load,
                modifier = Modifier.padding(padding),
            )
            is ProductDetailState.Loaded -> ProductContent(current.product, Modifier.padding(padding))
        }
    }
}

@Composable
private fun ProductContent(product: Product, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        ProductImage(
            product.imageUrl,
            Modifier
                .fillMaxWidth()
                .aspectRatio(1f),
        )
        product.categoryName?.let {
            Text(
                it,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Text(product.name, style = MaterialTheme.typography.headlineSmall)
        Text(
            product.price.toSoles(),
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.primary,
        )
        Text(
            text = if (product.isAvailable) "Disponibles: ${product.stock}" else "Agotado",
            style = MaterialTheme.typography.bodyMedium,
            color = if (product.isAvailable) {
                MaterialTheme.colorScheme.onSurfaceVariant
            } else {
                MaterialTheme.colorScheme.error
            },
        )
        product.description?.takeIf { it.isNotBlank() }?.let {
            Text(it, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

@Composable
private fun AddToCartBar(
    product: Product,
    quantityInCart: Int,
    onAdd: () -> Unit,
    onDecrease: () -> Unit,
    onCartClick: () -> Unit,
) {
    BottomAppBar {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (quantityInCart == 0) {
                Button(
                    onClick = onAdd,
                    enabled = product.isAvailable,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(if (product.isAvailable) "Agregar al carrito" else "Agotado")
                }
            } else {
                QuantityStepper(
                    quantity = quantityInCart,
                    onDecrease = onDecrease,
                    onIncrease = onAdd,
                    canIncrease = quantityInCart < Cart.maxQuantityFor(product),
                )
                OutlinedButton(onClick = onCartClick, modifier = Modifier.weight(1f)) {
                    Text("Ir al carrito")
                }
            }
        }
    }
}
