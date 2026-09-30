package com.abarrotes.app.ui.cart

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.abarrotes.app.data.OrderRepository
import com.abarrotes.app.data.SessionRepository
import com.abarrotes.app.data.model.OrderConfirmation
import com.abarrotes.app.data.model.Product
import com.abarrotes.app.data.session.Session
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed interface CheckoutState {
    data object Idle : CheckoutState
    data object Submitting : CheckoutState
    data class Success(val order: OrderConfirmation) : CheckoutState
    data class Error(val message: String) : CheckoutState
}

/**
 * Carrito en memoria. Vive a nivel de Activity (ver AbarrotesNavHost), así que lo
 * comparten catálogo, detalle y carrito; se pierde si el sistema mata la app.
 */
class CartViewModel(
    private val orderRepository: OrderRepository,
    private val sessionRepository: SessionRepository,
) : ViewModel() {

    private val _cart = MutableStateFlow(Cart())
    val cart: StateFlow<Cart> = _cart.asStateFlow()

    private val _checkout = MutableStateFlow<CheckoutState>(CheckoutState.Idle)
    val checkout: StateFlow<CheckoutState> = _checkout.asStateFlow()

    val session: StateFlow<Session?> = sessionRepository.session

    fun add(product: Product) = _cart.update { it.add(product) }

    fun decrease(product: Product) =
        _cart.update { it.setQuantity(product, it.quantityOf(product.id) - 1) }

    fun remove(productId: String) = _cart.update { it.remove(productId) }

    fun placeOrder(deliveryAddress: String) {
        val cart = _cart.value
        if (cart.isEmpty() || _checkout.value == CheckoutState.Submitting) return
        if (session.value == null) {
            _checkout.value = CheckoutState.Error("Inicia sesión para generar el pedido.")
            return
        }
        if (deliveryAddress.isBlank()) {
            _checkout.value = CheckoutState.Error("Ingresa la dirección de entrega.")
            return
        }

        _checkout.value = CheckoutState.Submitting
        viewModelScope.launch {
            orderRepository.placeOrder(deliveryAddress, cart.toOrderLines())
                .onSuccess { order ->
                    _cart.value = Cart()
                    _checkout.value = CheckoutState.Success(order)
                }
                .onFailure { error ->
                    _checkout.value = CheckoutState.Error(
                        error.message ?: "No se pudo generar el pedido.",
                    )
                }
        }
    }

    /** La pantalla llama esto después de mostrar el resultado del pedido. */
    fun consumeCheckoutResult() {
        _checkout.value = CheckoutState.Idle
    }

    fun logout() {
        viewModelScope.launch { sessionRepository.logout() }
    }
}
