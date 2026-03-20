plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


android {
    namespace = "com.example.super_nanny"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.super_nanny"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Use project keystore for consistent SHA-1 signing (needed for Google Sign-In).
    // In CI, this file is decoded from the DEBUG_KEYSTORE_BASE64 secret.
    // Locally, falls back to default debug keystore.
    val projectKeystore = file("keystore/debug.keystore")
    if (projectKeystore.exists()) {
        signingConfigs {
            create("release") {
                storeFile = projectKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
        buildTypes {
            release {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    } else {
        buildTypes {
            release {
                // Locally: sign with default debug key (same SHA-1 registered in Firebase)
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
