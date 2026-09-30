package com.abarrotes.app.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.abarrotes.app.data.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class AuthUiState(
    val isSubmitting: Boolean = false,
    val error: String? = null,
    val isDone: Boolean = false,
)

/** Login y registro. Al terminar bien, la sesión queda guardada y `isDone` pasa a true. */
class AuthViewModel(private val repository: AuthRepository) : ViewModel() {

    private val _state = MutableStateFlow(AuthUiState())
    val state: StateFlow<AuthUiState> = _state.asStateFlow()

    fun login(email: String, password: String) {
        if (email.isBlank() || password.isBlank()) {
            _state.value = AuthUiState(error = "Ingresa tu email y contraseña.")
            return
        }
        submit { repository.login(email, password) }
    }

    fun register(name: String, email: String, password: String, phone: String, address: String) {
        val error = when {
            name.isBlank() -> "Ingresa tu nombre."
            email.isBlank() -> "Ingresa tu email."
            password.length < MIN_PASSWORD_LENGTH -> "La contraseña debe tener al menos $MIN_PASSWORD_LENGTH caracteres."
            else -> null
        }
        if (error != null) {
            _state.value = AuthUiState(error = error)
            return
        }
        submit { repository.register(name, email, password, phone, address) }
    }

    private fun submit(block: suspend () -> Result<Unit>) {
        if (_state.value.isSubmitting) return
        _state.value = AuthUiState(isSubmitting = true)
        viewModelScope.launch {
            _state.value = block().fold(
                onSuccess = { AuthUiState(isDone = true) },
                onFailure = { AuthUiState(error = it.message) },
            )
        }
    }

    companion object {
        // Igual que la validación de POST /auth/register.
        const val MIN_PASSWORD_LENGTH = 8
    }
}
