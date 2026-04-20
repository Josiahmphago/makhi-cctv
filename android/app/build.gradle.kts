// ✅ PLUGINS
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ✅ ANDROID CONFIGURATIONS
android {
    namespace = "com.example.makhi_cctv"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.makhi_cctv"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    // ✅ Compile Options
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // ✅ Kotlin Options
    kotlinOptions {
        jvmTarget = "17"
    }

    // ❌ REMOVE SIGNING CONFIG (FOR NOW - TEST BUILD)
    // We will add this back later for Play Store

    // ✅ BUILD TYPES
    buildTypes {
        release {
            // 🔥 IMPORTANT FIX (DISABLE R8)
            isMinifyEnabled = false
            isShrinkResources = false

            // Keep default proguard (safe)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // ❌ NO signingConfig here (fixes keystore error)
        }

        debug {
            isMinifyEnabled = false
        }
    }

    // ✅ Packaging (prevents some duplicate issues)
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// ✅ DEPENDENCIES
dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")

    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // 🔥 FIX: REMOVE OLD PLAY CORE CONFLICT
    configurations.all {
        exclude(group = "com.google.android.play", module = "core")
    }
}
// ✅ Flutter Configuration
flutter {
    source = "../.."
}