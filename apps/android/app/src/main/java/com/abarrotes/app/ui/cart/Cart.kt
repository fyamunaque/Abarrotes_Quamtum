package com.abarrotes.app.ui.cart

import com.abarrotes.app.data.model.OrderLine
import com.abarrotes.app.data.model.Product
import java.math.BigDecimal

/** Tope por producto que acepta POST /orders. */
const val MAX_QUANTITY_PER_PRODUCT = 999

data class CartLine(val product: Product, val quantity: Int) {
    val subtotal: BigDecimal get() = product.price * quantity.toBigDecimal()
}

/**
 * Carrito inmutable: cada operación devuelve uno nuevo. El total es referencial; el que
 * vale es el que calcula el servidor al crear el pedido.
 */
data class Cart(val lines: List<CartLine> = emptyList()) {

    val itemCount: Int get() = lines.sumOf { it.quantity }

    val total: BigDecimal get() = lines.fold(BigDecimal.ZERO) { acc, line -> acc + line.subtotal }

    fun isEmpty() = lines.isEmpty()

    fun quantityOf(productId: String): Int =
        lines.firstOrNull { it.product.id == productId }?.quantity ?: 0

    fun add(product: Product, quantity: Int = 1): Cart =
        setQuantity(product, quantityOf(product.id) + quantity)

    /** Ajusta la cantidad al stock conocido; 0 o menos quita el producto. */
    fun setQuantity(product: Product, quantity: Int): Cart {
        val allowed = quantity.coerceAtMost(maxQuantityFor(product))
        if (allowed <= 0) return remove(product.id)

        val line = CartLine(product, allowed)
        return if (lines.any { it.product.id == product.id }) {
            copy(lines = lines.map { if (it.product.id == product.id) line else it })
        } else {
            copy(lines = lines + line)
        }
    }

    fun remove(productId: String): Cart = copy(lines = lines.filterNot { it.product.id == productId })

    fun toOrderLines(): List<OrderLine> = lines.map { OrderLine(it.product.id, it.quantity) }

    companion object {
        fun maxQuantityFor(product: Product): Int = minOf(product.stock, MAX_QUANTITY_PER_PRODUCT)
    }
}
