package com.abarrotes.app.data.remote

import kotlinx.serialization.Serializable

// Espejo de las respuestas de /apps/api. Los montos (Decimal en la base) llegan como
// string para no perder precisión: se convierten a BigDecimal en Mappers.kt.

@Serializable
data class CategoryDto(val id: String, val name: String)

@Serializable
data class ProductDto(
    val id: String,
    val name: String,
    val description: String? = null,
    val price: String,
    val imageUrl: String? = null,
    val active: Boolean = true,
    val currentStock: Int = 0,
    val category: CategoryDto? = null,
)

@Serializable
data class PageMetaDto(val total: Int, val page: Int, val limit: Int, val totalPages: Int)

@Serializable
data class PageDto<T>(val data: List<T>, val meta: PageMetaDto)

@Serializable
data class LoginRequest(val email: String, val password: String)

@Serializable
data class RegisterRequest(
    val email: String,
    val password: String,
    val name: String,
    val phone: String? = null,
    val address: String? = null,
)

@Serializable
data class RefreshRequest(val refreshToken: String)

@Serializable
data class UserDto(
    val id: String,
    val email: String,
    val name: String,
    val address: String? = null,
    val role: String,
)

@Serializable
data class AuthResponseDto(
    val accessToken: String,
    val refreshToken: String,
    val user: UserDto,
)

@Serializable
data class CreateOrderRequest(val deliveryAddress: String, val items: List<OrderItemRequest>)

@Serializable
data class OrderItemRequest(val productId: String, val quantity: Int)

@Serializable
data class OrderDto(
    val id: String,
    val status: String,
    val total: String,
    val deliveryAddress: String,
)
