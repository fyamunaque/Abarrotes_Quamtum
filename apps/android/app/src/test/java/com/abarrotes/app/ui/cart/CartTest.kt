package com.abarrotes.app.ui.cart

import com.abarrotes.app.data.model.OrderLine
import com.abarrotes.app.data.model.Product
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal

class CartTest {

    private val arroz = product("arroz", price = "4.5", stock = 10)
    private val aceite = product("aceite", price = "9.90", stock = 3)

    @Test
    fun `agregar el mismo producto suma cantidades en una sola línea`() {
        val cart = Cart().add(arroz).add(arroz).add(aceite)

        assertEquals(2, cart.lines.size)
        assertEquals(2, cart.quantityOf("arroz"))
        assertEquals(3, cart.itemCount)
    }

    @Test
    fun `el total usa BigDecimal sin errores de redondeo`() {
        val cart = Cart().setQuantity(arroz, 3).setQuantity(aceite, 1)

        assertEquals(BigDecimal("23.40"), cart.total.setScale(2))
    }

    @Test
    fun `no deja pedir más que el stock disponible`() {
        val cart = Cart().setQuantity(aceite, 50).add(aceite)

        assertEquals(3, cart.quantityOf("aceite"))
    }

    @Test
    fun `respeta el tope por producto de la API`() {
        val muchoStock = product("sal", price = "1", stock = 5_000)

        assertEquals(MAX_QUANTITY_PER_PRODUCT, Cart().setQuantity(muchoStock, 2_000).quantityOf("sal"))
    }

    @Test
    fun `bajar a cero quita el producto`() {
        val cart = Cart().add(arroz).setQuantity(arroz, 0)

        assertTrue(cart.isEmpty())
    }

    @Test
    fun `un producto agotado no entra al carrito`() {
        val agotado = product("azucar", price = "3", stock = 0)

        assertTrue(Cart().add(agotado).isEmpty())
    }

    @Test
    fun `las líneas del pedido solo llevan id y cantidad`() {
        val cart = Cart().setQuantity(arroz, 2).add(aceite)

        assertEquals(listOf(OrderLine("arroz", 2), OrderLine("aceite", 1)), cart.toOrderLines())
    }
}

internal fun product(id: String, price: String, stock: Int) = Product(
    id = id,
    name = id.replaceFirstChar { it.uppercase() },
    description = null,
    price = BigDecimal(price),
    imageUrl = null,
    stock = stock,
    categoryName = null,
)
