package com.abarrotes.app.ui.order

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.abarrotes.app.data.OrderRepository
import com.abarrotes.app.data.SessionRepository
import com.abarrotes.app.data.model.OrderSummary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChangedBy
import kotlinx.coroutines.launch

sealed interface MyOrdersState {
    data object LoginRequired : MyOrdersState
    data object Loading : MyOrdersState
    data class Loaded(val orders: List<OrderSummary>) : MyOrdersState
    data class Error(val message: String) : MyOrdersState
}

/** "Mis pedidos": se carga al abrir la pantalla y de nuevo al iniciar sesión. */
class MyOrdersViewModel(
    private val orderRepository: OrderRepository,
    sessionRepository: SessionRepository,
) : ViewModel() {

    private val _state = MutableStateFlow<MyOrdersState>(MyOrdersState.Loading)
    val state: StateFlow<MyOrdersState> = _state.asStateFlow()

    private var loggedIn = false

    init {
        viewModelScope.launch {
            // Solo reacciona a entrar o salir de la sesión, no a cada renovación de tokens.
            sessionRepository.session.distinctUntilChangedBy { it != null }.collect { session ->
                loggedIn = session != null
                if (loggedIn) refresh() else _state.value = MyOrdersState.LoginRequired
            }
        }
    }

    fun refresh() {
        if (!loggedIn) return
        _state.value = MyOrdersState.Loading
        viewModelScope.launch {
            _state.value = orderRepository.getMyOrders().fold(
                onSuccess = { MyOrdersState.Loaded(it) },
                onFailure = { MyOrdersState.Error(it.message ?: "No se pudieron cargar tus pedidos.") },
            )
        }
    }
}
