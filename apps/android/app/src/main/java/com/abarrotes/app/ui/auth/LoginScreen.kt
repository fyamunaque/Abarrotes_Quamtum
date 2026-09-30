package com.abarrotes.app.ui.auth

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun LoginScreen(
    viewModel: AuthViewModel,
    onLoggedIn: () -> Unit,
    onRegisterClick: () -> Unit,
    onBack: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }

    LaunchedEffect(state.isDone) { if (state.isDone) onLoggedIn() }

    AuthScaffold(
        title = "Iniciar sesión",
        state = state,
        submitLabel = "Ingresar",
        onSubmit = { viewModel.login(email, password) },
        onBack = onBack,
        fields = {
            AuthTextField(email, { email = it }, "Email", keyboardType = KeyboardType.Email)
            AuthTextField(password, { password = it }, "Contraseña", isPassword = true)
        },
        footer = {
            TextButton(onClick = onRegisterClick, modifier = Modifier.fillMaxWidth()) {
                Text("¿No tienes cuenta? Regístrate")
            }
        },
    )
}
