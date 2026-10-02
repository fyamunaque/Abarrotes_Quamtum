package com.abarrotes.app.ui.catalog

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.abarrotes.app.R
import com.abarrotes.app.data.model.Category
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
fun CatalogScreen(
    viewModel: CatalogViewModel,
    cartViewModel: CartViewModel,
    onProductClick: (String) -> Unit,
    onCartClick: () -> Unit,
    onMyOrdersClick: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val cart by cartViewModel.cart.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Image(
                        painter = painterResource(R.drawable.neils_logo),
                        contentDescription = "Neil's Food Services",
                        modifier = Modifier
                            .height(40.dp)
                            .clip(RoundedCornerShape(8.dp)),
                    )
                },
                actions = {
                    IconButton(onClick = onMyOrdersClick) {
                        Icon(Icons.AutoMirrored.Filled.List, contentDescription = "Mis pedidos")
                    }
                    CartActionButton(cart.itemCount, onCartClick)
                },
            )
        },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize(),
        ) {
            SearchField(query = state.query, onQueryChange = viewModel::onQueryChange)
            if (state.categories.isNotEmpty()) {
                CategoryChips(
                    categories = state.categories,
                    selectedId = state.selectedCategoryId,
                    onSelected = viewModel::onCategorySelected,
                )
            }
            when {
                state.isLoading -> LoadingState()
                state.products.isEmpty() && state.error != null -> MessageState(
                    message = state.error.orEmpty(),
                    actionLabel = "Reintentar",
                    onAction = viewModel::retry,
                )
                state.products.isEmpty() -> MessageState(
                    message = if (state.query.isBlank()) {
                        "Todavía no hay productos en esta categoría."
                    } else {
                        "No encontramos productos para \"${state.query.trim()}\"."
                    },
                )
                else -> ProductList(
                    state = state,
                    cart = cart,
                    onLoadMore = viewModel::loadMore,
                    onProductClick = onProductClick,
                    onAdd = cartViewModel::add,
                    onDecrease = cartViewModel::decrease,
                )
            }
        }
    }
}

@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    val focusManager = LocalFocusManager.current
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text("Buscar por nombre o código") },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Borrar búsqueda")
                }
            }
        },
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = { focusManager.clearFocus() }),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

@Composable
private fun CategoryChips(
    categories: List<Category>,
    selectedId: String?,
    onSelected: (String?) -> Unit,
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            FilterChip(
                selected = selectedId == null,
                onClick = { onSelected(null) },
                label = { Text("Todas") },
            )
        }
        items(categories, key = { it.id }) { category ->
            FilterChip(
                selected = category.id == selectedId,
                onClick = { onSelected(category.id) },
                label = { Text(category.name) },
            )
        }
    }
}

@Composable
private fun ProductList(
    state: CatalogUiState,
    cart: Cart,
    onLoadMore: () -> Unit,
    onProductClick: (String) -> Unit,
    onAdd: (Product) -> Unit,
    onDecrease: (Product) -> Unit,
) {
    val listState = rememberLazyListState()
    // Pide la siguiente página cuando faltan pocos productos para llegar al final.
    val nearEnd by remember {
        derivedStateOf {
            val info = listState.layoutInfo
            val lastVisible = info.visibleItemsInfo.lastOrNull()?.index ?: 0
            lastVisible >= info.totalItemsCount - LOAD_MORE_THRESHOLD
        }
    }
    LaunchedEffect(nearEnd) { if (nearEnd) onLoadMore() }

    LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
        items(state.products, key = { it.id }) { product ->
            ProductRow(
                product = product,
                quantityInCart = cart.quantityOf(product.id),
                onClick = { onProductClick(product.id) },
                onAdd = { onAdd(product) },
                onDecrease = { onDecrease(product) },
            )
            HorizontalDivider()
        }
        item {
            ListFooter(
                isLoadingMore = state.isLoadingMore,
                error = state.error,
                canLoadMore = state.canLoadMore,
                onRetry = onLoadMore,
            )
        }
    }
}

@Composable
private fun ProductRow(
    product: Product,
    quantityInCart: Int,
    onClick: () -> Unit,
    onAdd: () -> Unit,
    onDecrease: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProductImage(product.imageUrl, Modifier.size(64.dp))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(
                product.name,
                style = MaterialTheme.typography.titleMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            product.categoryName?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                product.price.toSoles(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
            )
            if (!product.isAvailable) {
                Text(
                    "Agotado",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }
        when {
            !product.isAvailable -> Unit
            quantityInCart == 0 -> FilledTonalButton(onClick = onAdd) { Text("Agregar") }
            else -> QuantityStepper(
                quantity = quantityInCart,
                onDecrease = onDecrease,
                onIncrease = onAdd,
                canIncrease = quantityInCart < Cart.maxQuantityFor(product),
            )
        }
    }
}

@Composable
private fun ListFooter(isLoadingMore: Boolean, error: String?, canLoadMore: Boolean, onRetry: () -> Unit) {
    Box(
        Modifier
            .fillMaxWidth()
            .padding(16.dp),
        contentAlignment = Alignment.Center,
    ) {
        when {
            isLoadingMore -> CircularProgressIndicator(Modifier.size(24.dp))
            error != null && canLoadMore -> TextButton(onClick = onRetry) {
                Text("No se pudieron cargar más productos. Reintentar")
            }
        }
    }
}

private const val LOAD_MORE_THRESHOLD = 5
