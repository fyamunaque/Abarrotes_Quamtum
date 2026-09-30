package com.abarrotes.app.ui.cart

import com.abarrotes.app.data.OrderRepository
import com.abarrotes.app.data.SessionRepository
import com.abarrotes.app.data.model.OrderConfirmation
import com.abarrotes.app.data.model.OrderLine
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
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

@OptIn(ExperimentalCoroutinesApi::class)
class CartViewModelTest {

    private val arroz = product("arroz", price = "4.50", stock = 10)
    private val orders = FakeOrderRepository()
    private val sessions = FakeSessionRepository()
    private lateinit var viewModel: CartViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        viewModel = CartViewModel(orders, sessions)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `un pedido exitoso vacía el carrito y devuelve la confirmación`() {
        viewModel.add(arroz)
        viewModel.add(arroz)

        viewModel.placeOrder("Av. Siempre Viva 123")

        assertEquals("Av. Siempre Viva 123", orders.lastAddress)
        assertEquals(listOf(OrderLine("arroz", 2)), orders.lastLines)
        assertTrue(viewModel.cart.value.isEmpty())
        assertEquals(CheckoutState.Success(orders.confirmation), viewModel.checkout.value)
    }

    @Test
    fun `si el pedido falla el carrito se conserva y se muestra el mensaje del servidor`() {
        orders.error = ApiException("Stock insuficiente para \"Arroz\"")
        viewModel.add(arroz)

        viewModel.placeOrder("Av. Siempre Viva 123")

        assertEquals(1, viewModel.cart.value.itemCount)
        assertEquals(CheckoutState.Error("Stock insuficiente para \"Arroz\""), viewModel.checkout.value)
    }

    @Test
    fun `sin sesión no llama a la API`() {
        sessions.session.value = null
        viewModel.add(arroz)

        viewModel.placeOrder("Av. Siempre Viva 123")

        assertEquals(null, orders.lastLines)
        assertTrue(viewModel.checkout.value is CheckoutState.Error)
    }

    @Test
    fun `sin dirección no llama a la API`() {
        viewModel.add(arroz)

        viewModel.placeOrder("   ")

        assertEquals(null, orders.lastLines)
        assertTrue(viewModel.checkout.value is CheckoutState.Error)
    }

    @Test
    fun `con el carrito vacío no hace nada`() {
        viewModel.placeOrder("Av. Siempre Viva 123")

        assertEquals(null, orders.lastLines)
        assertEquals(CheckoutState.Idle, viewModel.checkout.value)
    }
}

private class FakeOrderRepository : OrderRepository {
    val confirmation = OrderConfirmation("order-1", BigDecimal("9.00"), "PENDING_CONFIRMATION")
    var error: Exception? = null
    var lastAddress: String? = null
    var lastLines: List<OrderLine>? = null

    override suspend fun placeOrder(deliveryAddress: String, lines: List<OrderLine>): Result<OrderConfirmation> {
        lastAddress = deliveryAddress
        lastLines = lines
        return error?.let { Result.failure(it) } ?: Result.success(confirmation)
    }
}

private class FakeSessionRepository : SessionRepository {
    override val session = MutableStateFlow<Session?>(
        Session("access", "refresh", "Cliente", "cliente@example.com", null),
    )

    override suspend fun logout() {
        session.value = null
    }
}
