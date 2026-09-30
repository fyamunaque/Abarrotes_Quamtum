package com.abarrotes.app.data.session

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.abarrotes.app.data.remote.AuthResponseDto
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.runBlocking
import java.io.IOException

data class Session(
    val accessToken: String,
    val refreshToken: String,
    val userName: String,
    val userEmail: String,
    val userAddress: String?,
)

private val Context.sessionDataStore by preferencesDataStore(name = "session")

/** Tokens y datos básicos del usuario, persistidos con DataStore. */
class SessionStore(context: Context, scope: CoroutineScope) {
    private val dataStore: DataStore<Preferences> = context.applicationContext.sessionDataStore

    private val sessions: Flow<Session?> = dataStore.data
        .catch { e -> if (e is IOException) emit(emptyPreferences()) else throw e }
        .map { it.toSession() }

    val session: StateFlow<Session?> = sessions.stateIn(scope, SharingStarted.Eagerly, null)

    /** Para los interceptores de OkHttp, que corren en hilos de red y no pueden suspender. */
    fun currentBlocking(): Session? = runBlocking { sessions.first() }

    suspend fun save(auth: AuthResponseDto) {
        dataStore.edit { prefs ->
            prefs[ACCESS_TOKEN] = auth.accessToken
            prefs[REFRESH_TOKEN] = auth.refreshToken
            prefs[USER_NAME] = auth.user.name
            prefs[USER_EMAIL] = auth.user.email
            val address = auth.user.address
            if (address.isNullOrBlank()) prefs.remove(USER_ADDRESS) else prefs[USER_ADDRESS] = address
        }
    }

    suspend fun clear() {
        dataStore.edit { it.clear() }
    }

    private fun Preferences.toSession(): Session? {
        val access = this[ACCESS_TOKEN] ?: return null
        val refresh = this[REFRESH_TOKEN] ?: return null
        return Session(
            accessToken = access,
            refreshToken = refresh,
            userName = this[USER_NAME].orEmpty(),
            userEmail = this[USER_EMAIL].orEmpty(),
            userAddress = this[USER_ADDRESS],
        )
    }

    private companion object {
        val ACCESS_TOKEN = stringPreferencesKey("access_token")
        val REFRESH_TOKEN = stringPreferencesKey("refresh_token")
        val USER_NAME = stringPreferencesKey("user_name")
        val USER_EMAIL = stringPreferencesKey("user_email")
        val USER_ADDRESS = stringPreferencesKey("user_address")
    }
}
