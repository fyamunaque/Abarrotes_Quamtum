package com.abarrotes.app.di

import android.content.Context
import com.abarrotes.app.BuildConfig
import com.abarrotes.app.data.AuthRepository
import com.abarrotes.app.data.CatalogRepository
import com.abarrotes.app.data.OrderRepository
import com.abarrotes.app.data.RemoteOrderRepository
import com.abarrotes.app.data.remote.AbarrotesApi
import com.abarrotes.app.data.remote.AuthInterceptor
import com.abarrotes.app.data.remote.AuthRefreshApi
import com.abarrotes.app.data.remote.TokenAuthenticator
import com.abarrotes.app.data.session.SessionStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.create

/** Inyección de dependencias manual: una instancia por app, creada en AbarrotesApplication. */
class AppContainer(context: Context) {

    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
    }

    val sessionStore = SessionStore(context, appScope)

    // BASIC: método, URL y código. Nunca BODY, que dejaría contraseñas y tokens en logcat.
    private val logging = HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BASIC else HttpLoggingInterceptor.Level.NONE
    }

    private fun retrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.API_BASE_URL)
        .client(client)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()

    // Cliente aparte, sin authenticator, para que un refresh fallido no se reintente en bucle.
    private val refreshApi: AuthRefreshApi =
        retrofit(OkHttpClient.Builder().addInterceptor(logging).build()).create()

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor(sessionStore))
        .authenticator(TokenAuthenticator(sessionStore, refreshApi))
        .addInterceptor(logging)
        .build()

    private val api: AbarrotesApi = retrofit(okHttpClient).create()

    val catalogRepository = CatalogRepository(api, json)
    val authRepository = AuthRepository(api, sessionStore, json)
    val orderRepository: OrderRepository = RemoteOrderRepository(api, json)
}
