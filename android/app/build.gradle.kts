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

    val keyProperties = Properties().also {
        val properties = rootProject.file("key.properties")
        if (properties.exists())
            it.load(properties.inputStream())
    }

    signingConfigs {
        create("release") {
            storeFile = keyProperties.getProperty("storeFile")?.let { file(it) } ?: signingConfigs["debug"]?.storeFile
            storePassword = keyProperties.getProperty("storePassword") ?: signingConfigs["debug"]?.storePassword
            keyAlias = keyProperties.getProperty("keyAlias") ?: signingConfigs["debug"]?.keyAlias
            keyPassword = keyProperties.getProperty("keyPassword") ?: signingConfigs["debug"]?.keyPassword
            enableV1Signing = true
            enableV2Signing = true
        }
        create("debug") {
            storeFile = keyProperties.getProperty("storeFile")?.let { file(it) } ?: signingConfigs["debug"]?.storeFile
            storePassword = keyProperties.getProperty("storePassword") ?: signingConfigs["debug"]?.storePassword
            keyAlias = keyProperties.getProperty("keyAlias") ?: signingConfigs["debug"]?.keyAlias
            keyPassword = keyProperties.getProperty("keyPassword") ?: signingConfigs["debug"]?.keyPassword
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs["release"]
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs["debug"]
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}
