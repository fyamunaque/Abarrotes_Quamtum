package com.abarrotes.app.ui.auth

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun RegisterScreen(
    viewModel: AuthViewModel,
    onRegistered: () -> Unit,
    onBack: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var phone by rememberSaveable { mutableStateOf("") }
    var address by rememberSaveable { mutableStateOf("") }

    LaunchedEffect(state.isDone) { if (state.isDone) onRegistered() }

    AuthScaffold(
        title = "Crear cuenta",
        state = state,
        submitLabel = "Registrarme",
        onSubmit = { viewModel.register(name, email, password, phone, address) },
        onBack = onBack,
        fields = {
            AuthTextField(name, { name = it }, "Nombre")
            AuthTextField(email, { email = it }, "Email", keyboardType = KeyboardType.Email)
            AuthTextField(
                password,
                { password = it },
                "Contraseña (mín. ${AuthViewModel.MIN_PASSWORD_LENGTH} caracteres)",
                isPassword = true,
            )
            AuthTextField(phone, { phone = it }, "Teléfono (opcional)", keyboardType = KeyboardType.Phone)
            AuthTextField(address, { address = it }, "Dirección de entrega (opcional)")
        },
    )
}
