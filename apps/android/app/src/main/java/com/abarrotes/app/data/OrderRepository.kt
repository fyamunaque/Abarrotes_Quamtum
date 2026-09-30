package com.abarrotes.app.data

import com.abarrotes.app.data.model.OrderConfirmation
import com.abarrotes.app.data.model.OrderLine
import com.abarrotes.app.data.model.toDomain
import com.abarrotes.app.data.remote.AbarrotesApi
import com.abarrotes.app.data.remote.CreateOrderRequest
import com.abarrotes.app.data.remote.OrderItemRequest
import com.abarrotes.app.data.remote.safeApiCall
import kotlinx.serialization.json.Json

interface OrderRepository {
    suspend fun placeOrder(deliveryAddress: String, lines: List<OrderLine>): Result<OrderConfirmation>
}

/** POST /orders. Solo envía productos y cantidades: precios y total los calcula el servidor. */
class RemoteOrderRepository(private val api: AbarrotesApi, private val json: Json) : OrderRepository {
    override suspend fun placeOrder(
        deliveryAddress: String,
        lines: List<OrderLine>,
    ): Result<OrderConfirmation> = safeApiCall(json) {
        api.createOrder(
            CreateOrderRequest(
                deliveryAddress = deliveryAddress.trim(),
                items = lines.map { OrderItemRequest(it.productId, it.quantity) },
            ),
        ).toDomain()
    }
}
