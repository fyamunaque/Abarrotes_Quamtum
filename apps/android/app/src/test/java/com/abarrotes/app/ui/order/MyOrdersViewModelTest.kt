package com.abarrotes.app.ui.order

import com.abarrotes.app.data.OrderRepository
import com.abarrotes.app.data.SessionRepository
import com.abarrotes.app.data.model.OrderConfirmation
import com.abarrotes.app.data.model.OrderLine
import com.abarrotes.app.data.model.OrderSummary
import com.abarrotes.app.data.remote.ApiException
import com.abarrotes.app.data.session.Session
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

@OptIn(ExperimentalCoroutinesApi::class)
class MyOrdersViewModelTest {

    private val order = OrderSummary("o1", "CONFIRMED", BigDecimal("9.00"), "Calle 1", null, emptyList())
    private val orders = FakeOrders()
    private val sessions = MutableStateFlow<Session?>(null)
    private val sessionRepository = object : SessionRepository {
        override val session = sessions
        override suspend fun logout() {
            sessions.value = null
        }
    }

    @Before
    fun setUp() = Dispatchers.setMain(UnconfinedTestDispatcher())

    @After
    fun tearDown() = Dispatchers.resetMain()

    @Test
    fun `sin sesión pide iniciar sesión y no llama a la API`() {
        val viewModel = MyOrdersViewModel(orders, sessionRepository)

        assertEquals(MyOrdersState.LoginRequired, viewModel.state.value)
        assertEquals(0, orders.calls)
    }

    @Test
    fun `al iniciar sesión carga los pedidos`() {
        val viewModel = MyOrdersViewModel(orders, sessionRepository)

        sessions.value = session("access-1")

        assertEquals(MyOrdersState.Loaded(listOf(order)), viewModel.state.value)
        assertEquals(1, orders.calls)
    }

    @Test
    fun `renovar los tokens no vuelve a cargar la lista`() {
        sessions.value = session("access-1")
        MyOrdersViewModel(orders, sessionRepository)

        sessions.value = session("access-2")

        assertEquals(1, orders.calls)
    }

    @Test
    fun `muestra el error de la API y permite reintentar`() {
        sessions.value = session("access-1")
        orders.error = ApiException("No se pudo conectar con el servidor.")
        val viewModel = MyOrdersViewModel(orders, sessionRepository)

        assertEquals(MyOrdersState.Error("No se pudo conectar con el servidor."), viewModel.state.value)

        orders.error = null
        viewModel.refresh()
        assertEquals(MyOrdersState.Loaded(listOf(order)), viewModel.state.value)
    }

    private fun session(access: String) = Session(access, "refresh", "Cliente", "c@example.com", null)

    private inner class FakeOrders : OrderRepository {
        var calls = 0
        var error: Exception? = null

        override suspend fun placeOrder(deliveryAddress: String, lines: List<OrderLine>): Result<OrderConfirmation> =
            error("no se usa")

        override suspend fun getMyOrders(): Result<List<OrderSummary>> {
            calls++
            return error?.let { Result.failure(it) } ?: Result.success(listOf(order))
        }
    }
}
