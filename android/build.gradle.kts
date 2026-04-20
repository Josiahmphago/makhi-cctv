// ✅ Top-level Gradle settings file
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2") // ✅ Latest AGP version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // ✅ Stable Kotlin version
        classpath("com.google.gms:google-services:4.4.0") // ✅ Firebase Plugin
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ FIX: Convert buildDir to `File` type to avoid error
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
