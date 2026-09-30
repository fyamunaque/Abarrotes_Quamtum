package com.abarrotes.app.data.remote

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import retrofit2.HttpException
import java.io.IOException

/** Error listo para mostrar al usuario. */
class ApiException(message: String, val code: Int? = null) : Exception(message)

/**
 * Ejecuta una llamada a la API y convierte los fallos esperables en [ApiException].
 * La cancelación de corrutinas no se captura, así que se propaga normalmente.
 */
suspend fun <T> safeApiCall(json: Json, block: suspend () -> T): Result<T> =
    try {
        Result.success(block())
    } catch (e: HttpException) {
        val body = e.response()?.errorBody()?.string()
        Result.failure(ApiException(parseApiErrorMessage(json, body, e.code()), e.code()))
    } catch (e: IOException) {
        Result.failure(ApiException("No se pudo conectar con el servidor. Revisa tu conexión."))
    } catch (e: IllegalArgumentException) {
        // Incluye SerializationException y montos que no se pueden convertir a BigDecimal.
        Result.failure(ApiException("El servidor respondió algo inesperado."))
    }

/**
 * Extrae el mensaje de un error de NestJS: `{ "statusCode": 400, "message": "..." | ["...", "..."] }`.
 */
fun parseApiErrorMessage(json: Json, body: String?, code: Int): String {
    val message = runCatching {
        when (val value = (json.parseToJsonElement(body.orEmpty()) as? JsonObject)?.get("message")) {
            is JsonPrimitive -> value.content
            is JsonArray -> value.joinToString("\n") { (it as? JsonPrimitive)?.content.orEmpty() }
            else -> null
        }
    }.getOrNull()

    if (!message.isNullOrBlank()) return message
    return when (code) {
        401 -> "Tu sesión expiró. Inicia sesión de nuevo."
        403 -> "No tienes permisos para esta acción."
        404 -> "No encontramos lo que buscabas."
        in 500..599 -> "El servidor tuvo un problema. Intenta en unos minutos."
        else -> "Ocurrió un error ($code)."
    }
}
