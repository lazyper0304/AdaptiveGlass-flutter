import org.jetbrains.kotlin.konan.properties.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.adaptive_glass_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.adaptive_glass_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packagingOptions.jniLibs.useLegacyPackaging = true
    packagingOptions.dex.useLegacyPackaging = true

    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = Properties()
    if (keyPropertiesFile.exists()) {
        keyProperties.load(keyPropertiesFile.inputStream())
    }

    val storeFile = keyProperties.getProperty("storeFile")?.let { file(it) }
    val storePassword = keyProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
    val keyAlias = keyProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
    val keyPassword = keyProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")

    val hasSigningConfig = storePassword != null && keyAlias != null && keyPassword != null

    signingConfigs {
        create("release") {
            storeFile?.let { this.storeFile = it }
            storePassword?.let { this.storePassword = it }
            keyAlias?.let { this.keyAlias = it }
            keyPassword?.let { this.keyPassword = it }
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            if (hasSigningConfig) {
                signingConfig = signingConfigs["release"]
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            if (hasSigningConfig) {
                signingConfig = signingConfigs["release"]
            }
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}
