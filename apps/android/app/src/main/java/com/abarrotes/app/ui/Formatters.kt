package com.abarrotes.app.ui

import java.math.BigDecimal
import java.math.RoundingMode

/** Montos en soles: `S/ 4.50`. */
fun BigDecimal.toSoles(): String = "S/ " + setScale(2, RoundingMode.HALF_UP).toPlainString()

/**
 * Texto de cada estado de pedido. Debe coincidir con el enum OrderStatus de
 * prisma/schema.prisma (ver CLAUDE.md antes de agregar estados).
 */
fun orderStatusLabel(status: String): String = when (status) {
    "PENDING_CONFIRMATION" -> "Pendiente de confirmación"
    "CONFIRMED" -> "Confirmado"
    "OUT_FOR_DELIVERY" -> "En camino"
    "DELIVERED" -> "Entregado"
    "CANCELLED" -> "Cancelado"
    else -> status
}
