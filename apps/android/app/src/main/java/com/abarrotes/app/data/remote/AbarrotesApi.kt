package com.abarrotes.app.data.remote

import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

/** Endpoints de /apps/api que usa la app. Ver apps/api/README.md. */
interface AbarrotesApi {
    @GET("categories")
    suspend fun getCategories(): List<CategoryDto>

    @GET("products")
    suspend fun getProducts(
        @Query("categoryId") categoryId: String?,
        @Query("search") search: String?,
        @Query("page") page: Int,
        @Query("limit") limit: Int,
    ): PageDto<ProductDto>

    @GET("products/{id}")
    suspend fun getProduct(@Path("id") id: String): ProductDto

    @POST("auth/login")
    suspend fun login(@Body body: LoginRequest): AuthResponseDto

    @POST("auth/register")
    suspend fun register(@Body body: RegisterRequest): AuthResponseDto

    @POST("orders")
    suspend fun createOrder(@Body body: CreateOrderRequest): OrderDto

    /** Pedidos del usuario del token, del más reciente al más antiguo. */
    @GET("orders/mine")
    suspend fun getMyOrders(
        @Query("page") page: Int,
        @Query("limit") limit: Int,
    ): PageDto<OrderDto>
}

/**
 * Refresh de tokens. Va aparte y es síncrono porque lo llama el Authenticator de OkHttp,
 * que corre en un hilo de red y no puede suspender.
 */
interface AuthRefreshApi {
    @POST("auth/refresh")
    fun refresh(@Body body: RefreshRequest): Call<AuthResponseDto>
}
