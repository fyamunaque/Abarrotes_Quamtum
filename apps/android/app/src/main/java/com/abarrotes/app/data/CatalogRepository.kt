package com.abarrotes.app.data

import com.abarrotes.app.data.model.Category
import com.abarrotes.app.data.model.Product
import com.abarrotes.app.data.model.ProductPage
import com.abarrotes.app.data.model.toDomain
import com.abarrotes.app.data.remote.AbarrotesApi
import com.abarrotes.app.data.remote.safeApiCall
import kotlinx.serialization.json.Json

class CatalogRepository(private val api: AbarrotesApi, private val json: Json) {

    suspend fun getCategories(): Result<List<Category>> =
        safeApiCall(json) { api.getCategories().map { it.toDomain() } }

    suspend fun getProducts(categoryId: String?, search: String, page: Int): Result<ProductPage> =
        safeApiCall(json) {
            api.getProducts(
                categoryId = categoryId,
                search = search.takeIf { it.isNotBlank() },
                page = page,
                limit = PAGE_SIZE,
            ).toDomain()
        }

    suspend fun getProduct(id: String): Result<Product> =
        safeApiCall(json) { api.getProduct(id).toDomain() }

    companion object {
        const val PAGE_SIZE = 20
    }
}
