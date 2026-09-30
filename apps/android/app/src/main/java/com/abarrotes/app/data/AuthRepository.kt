package com.abarrotes.app.data

import com.abarrotes.app.data.remote.AbarrotesApi
import com.abarrotes.app.data.remote.LoginRequest
import com.abarrotes.app.data.remote.RegisterRequest
import com.abarrotes.app.data.remote.safeApiCall
import com.abarrotes.app.data.session.Session
import com.abarrotes.app.data.session.SessionStore
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json

/** Lo que el carrito necesita saber de la sesión (interfaz para poder simularla en tests). */
interface SessionRepository {
    val session: StateFlow<Session?>
    suspend fun logout()
}

class AuthRepository(
    private val api: AbarrotesApi,
    private val sessionStore: SessionStore,
    private val json: Json,
) : SessionRepository {

    override val session: StateFlow<Session?> = sessionStore.session

    suspend fun login(email: String, password: String): Result<Unit> =
        safeApiCall(json) { api.login(LoginRequest(email.trim(), password)) }
            .map { sessionStore.save(it) }

    suspend fun register(
        name: String,
        email: String,
        password: String,
        phone: String,
        address: String,
    ): Result<Unit> =
        safeApiCall(json) {
            api.register(
                RegisterRequest(
                    email = email.trim(),
                    password = password,
                    name = name.trim(),
                    phone = phone.trim().ifBlank { null },
                    address = address.trim().ifBlank { null },
                ),
            )
        }.map { sessionStore.save(it) }

    // Los tokens son stateless en el backend: cerrar sesión es olvidarlos en el dispositivo.
    override suspend fun logout() = sessionStore.clear()
}
