package com.abarrotes.app.data.remote

import com.abarrotes.app.data.session.SessionStore
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import java.io.IOException

/**
 * Ante un 401, renueva los tokens con el refresh token y reintenta la petición una vez.
 * Si el refresh es rechazado, cierra la sesión: el usuario tendrá que volver a ingresar.
 */
class TokenAuthenticator(
    private val sessionStore: SessionStore,
    private val refreshApi: AuthRefreshApi,
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        val failedToken = response.request.header(AUTHORIZATION)?.removePrefix("Bearer ")
            ?: return null // La petición no llevaba token: no hay nada que renovar.
        if (response.priorResponse != null) return null // Ya se reintentó una vez.

        synchronized(this) {
            val session = sessionStore.currentBlocking() ?: return null
            // Otro hilo ya renovó los tokens mientras este esperaba.
            if (session.accessToken != failedToken) {
                return response.request.withBearer(session.accessToken)
            }

            val refresh = try {
                refreshApi.refresh(RefreshRequest(session.refreshToken)).execute()
            } catch (e: IOException) {
                return null // Sin red: no se cierra la sesión por esto.
            }

            val body = refresh.body()
            if (!refresh.isSuccessful || body == null) {
                runBlocking { sessionStore.clear() }
                return null
            }
            runBlocking { sessionStore.save(body) }
            return response.request.withBearer(body.accessToken)
        }
    }
}
