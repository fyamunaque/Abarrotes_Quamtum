package com.abarrotes.app.ui.catalog

import com.abarrotes.app.data.CatalogRepository
import com.abarrotes.app.data.remote.AbarrotesApi
import com.abarrotes.app.data.remote.AuthResponseDto
import com.abarrotes.app.data.remote.CategoryDto
import com.abarrotes.app.data.remote.CreateOrderRequest
import com.abarrotes.app.data.remote.LoginRequest
import com.abarrotes.app.data.remote.OrderDto
import com.abarrotes.app.data.remote.PageDto
import com.abarrotes.app.data.remote.PageMetaDto
import com.abarrotes.app.data.remote.ProductDto
import com.abarrotes.app.data.remote.RegisterRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlinx.serialization.json.Json
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.IOException

@OptIn(ExperimentalCoroutinesApi::class)
class CatalogViewModelTest {

    private val api = FakeApi()

    @After
    fun tearDown() = Dispatchers.resetMain()

    private fun TestScope.newViewModel(): CatalogViewModel {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        return CatalogViewModel(CatalogRepository(api, Json { ignoreUnknownKeys = true }))
    }

    @Test
    fun `si las categorías fallan al abrir, se reintentan cuando cargan los productos`() = runTest {
        // Emulador recién encendido: la primera petición sale antes de que haya red.
        api.categoryFailures = 1
        val viewModel = newViewModel()

        advanceUntilIdle()

        assertEquals(listOf("Abarrotes", "Bebidas"), viewModel.state.value.categories.map { it.name })
        assertEquals(2, api.categoryCalls)
        assertEquals(1, viewModel.state.value.products.size)
    }

    @Test
    fun `con las categorías cargadas no se vuelven a pedir al buscar`() = runTest {
        val viewModel = newViewModel()
        advanceUntilIdle()

        viewModel.onQueryChange("arroz")
        advanceUntilIdle()

        assertEquals(1, api.categoryCalls)
        assertEquals(2, api.productCalls)
    }

    private class FakeApi : AbarrotesApi {
        var categoryFailures = 0
        var categoryCalls = 0
        var productCalls = 0

        override suspend fun getCategories(): List<CategoryDto> {
            categoryCalls++
            if (categoryFailures > 0) {
                categoryFailures--
                throw IOException("Failed to connect to /10.0.2.2:3001")
            }
            return listOf(CategoryDto("c1", "Abarrotes"), CategoryDto("c2", "Bebidas"))
        }

        override suspend fun getProducts(
            categoryId: String?,
            search: String?,
            page: Int,
            limit: Int,
        ): PageDto<ProductDto> {
            productCalls++
            val rice = ProductDto(id = "p1", name = "Arroz extra 1 kg", price = "4.50", currentStock = 50)
            return PageDto(listOf(rice), PageMetaDto(total = 1, page = 1, limit = limit, totalPages = 1))
        }

        override suspend fun getProduct(id: String): ProductDto = error("no se usa")
        override suspend fun login(body: LoginRequest): AuthResponseDto = error("no se usa")
        override suspend fun register(body: RegisterRequest): AuthResponseDto = error("no se usa")
        override suspend fun createOrder(body: CreateOrderRequest): OrderDto = error("no se usa")
        override suspend fun getMyOrders(page: Int, limit: Int): PageDto<OrderDto> = error("no se usa")
    }
}
