plugins {
    alias(libs.plugins.android.application) apply false
    // AGP 9 compila Kotlin por sí mismo (no se aplica kotlin-android en los módulos);
    // declararlo aquí solo fija la versión de Kotlin que usa, la misma que los plugins de abajo.
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
