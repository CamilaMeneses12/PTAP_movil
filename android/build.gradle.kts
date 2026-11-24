plugins {
    // Solo para tener las clases de Kotlin disponibles en este archivo (la versión está en settings.gradle.kts)
    id("org.jetbrains.kotlin.android") apply false
}

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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// tflite_flutter compila su Java para Java 11, pero Kotlin 2.4 usaría Java 25 por defecto y Gradle
// rechaza la mezcla ("Inconsistent JVM Target Compatibility"). Se alinea Kotlin a 11 solo en ese paquete.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        if (project.name == "tflite_flutter") {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}
