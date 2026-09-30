package com.abarrotes.app.ui.product

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.abarrotes.app.data.CatalogRepository
import com.abarrotes.app.data.model.Product
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface ProductDetailState {
    data object Loading : ProductDetailState
    data class Loaded(val product: Product) : ProductDetailState
    data class Error(val message: String) : ProductDetailState
}

class ProductDetailViewModel(
    private val productId: String,
    private val repository: CatalogRepository,
) : ViewModel() {

    private val _state = MutableStateFlow<ProductDetailState>(ProductDetailState.Loading)
    val state: StateFlow<ProductDetailState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        _state.value = ProductDetailState.Loading
        viewModelScope.launch {
            _state.value = repository.getProduct(productId).fold(
                onSuccess = { ProductDetailState.Loaded(it) },
                onFailure = { ProductDetailState.Error(it.message ?: "No se pudo cargar el producto.") },
            )
        }
    }
}
