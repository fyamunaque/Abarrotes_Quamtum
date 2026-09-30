package com.abarrotes.app.data.remote

import com.abarrotes.app.data.session.SessionStore
import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.Response

/** Agrega el access token, si hay sesión. En las rutas públicas la API lo ignora. */
class AuthInterceptor(private val sessionStore: SessionStore) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val token = sessionStore.currentBlocking()?.accessToken
        if (token == null || request.header(AUTHORIZATION) != null) {
            return chain.proceed(request)
        }
        return chain.proceed(request.withBearer(token))
    }
}

internal const val AUTHORIZATION = "Authorization"

internal fun Request.withBearer(token: String): Request =
    newBuilder().header(AUTHORIZATION, "Bearer $token").build()
