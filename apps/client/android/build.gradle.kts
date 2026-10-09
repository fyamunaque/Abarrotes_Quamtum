allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// NDK único para todos los módulos de Android: el 30 que instala Android Studio
// (SDK Manager → SDK Tools → NDK (Side by side)). Flutter 3.47 y el plugin jni
// (llega con google_fonts → path_provider, y compila código nativo) piden el
// 28.2 (flutter.ndkVersion). Cuando falta, Flutter intenta instalarlo con
// sdkmanager.bat, que en Windows falla porque cmd parte el argumento
// "ndk;<versión>". finalizeDsl corre después del build.gradle de cada módulo,
// así que este valor gana. Tiene que ir antes de evaluationDependsOn(":app"):
// si no, la app ya está evaluada y el plugin de Flutter ve el 28.2 primero.
// Revisarlo al actualizar Flutter.
val neilsNdkVersion = "30.0.16248370"
subprojects {
    pluginManager.withPlugin("com.android.application") {
        extensions
            .getByType(com.android.build.api.variant.ApplicationAndroidComponentsExtension::class.java)
            .finalizeDsl { it.ndkVersion = neilsNdkVersion }
    }
    pluginManager.withPlugin("com.android.library") {
        extensions
            .getByType(com.android.build.api.variant.LibraryAndroidComponentsExtension::class.java)
            .finalizeDsl { it.ndkVersion = neilsNdkVersion }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
