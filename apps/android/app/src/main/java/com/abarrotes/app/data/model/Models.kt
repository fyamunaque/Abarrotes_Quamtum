package com.abarrotes.app.data.model

import com.abarrotes.app.data.remote.CategoryDto
import com.abarrotes.app.data.remote.OrderDto
import com.abarrotes.app.data.remote.PageDto
import com.abarrotes.app.data.remote.ProductDto
import java.math.BigDecimal

data class Category(val id: String, val name: String)

data class Product(
    val id: String,
    val name: String,
    val description: String?,
    val price: BigDecimal,
    val imageUrl: String?,
    val stock: Int,
    val categoryName: String?,
) {
    val isAvailable: Boolean get() = stock > 0
}

data class ProductPage(val products: List<Product>, val page: Int, val totalPages: Int)

data class OrderLine(val productId: String, val quantity: Int)

data class OrderConfirmation(val id: String, val total: BigDecimal, val status: String)

fun CategoryDto.toDomain() = Category(id = id, name = name)

fun ProductDto.toDomain() = Product(
    id = id,
    name = name,
    description = description,
    price = BigDecimal(price),
    imageUrl = imageUrl,
    stock = currentStock,
    categoryName = category?.name,
)

fun PageDto<ProductDto>.toDomain() = ProductPage(
    products = data.map { it.toDomain() },
    page = meta.page,
    totalPages = meta.totalPages,
)

fun OrderDto.toDomain() = OrderConfirmation(id = id, total = BigDecimal(total), status = status)
