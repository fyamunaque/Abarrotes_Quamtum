package com.abarrotes.app.data.remote

import com.abarrotes.app.data.model.toDomain
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal

/** Verifica que la app entiende las respuestas reales de /apps/api. */
class ApiParsingTest {

    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
    }

    @Test
    fun `parsea GET products con precio como string y campos extra`() {
        // Forma exacta que devuelve NestJS: Prisma serializa Decimal como string ("4.5").
        val body = """
            {
              "data": [{
                "id": "p1", "name": "Arroz 1kg", "description": null, "sku": "ARZ-1KG",
                "price": "4.5", "imageUrl": null, "active": true, "currentStock": 12,
                "minStock": 2, "expirationDate": null, "createdAt": "2026-09-01T00:00:00.000Z",
                "categoryId": "c1", "category": { "id": "c1", "name": "Abarrotes" }
              }],
              "meta": { "total": 41, "page": 1, "limit": 20, "totalPages": 3 }
            }
        """.trimIndent()

        val page = json.decodeFromString<PageDto<ProductDto>>(body).toDomain()

        assertEquals(3, page.totalPages)
        val product = page.products.single()
        assertEquals(BigDecimal("4.5"), product.price)
        assertEquals(12, product.stock)
        assertEquals("Abarrotes", product.categoryName)
    }

    @Test
    fun `toma el mensaje de error de NestJS, sea texto o lista`() {
        assertEquals(
            "Stock insuficiente para \"Arroz\"",
            parseApiErrorMessage(json, """{"statusCode":409,"message":"Stock insuficiente para \"Arroz\""}""", 409),
        )
        assertEquals(
            "email must be an email\npassword must be longer than or equal to 8 characters",
            parseApiErrorMessage(
                json,
                """{"statusCode":400,"message":["email must be an email","password must be longer than or equal to 8 characters"]}""",
                400,
            ),
        )
    }

    @Test
    fun `usa un mensaje genérico si el cuerpo no es JSON`() {
        assertEquals("Tu sesión expiró. Inicia sesión de nuevo.", parseApiErrorMessage(json, "<html>", 401))
        assertEquals("El servidor tuvo un problema. Intenta en unos minutos.", parseApiErrorMessage(json, null, 502))
    }
}
