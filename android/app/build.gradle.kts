plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.appTenda"
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
        // O applicationId base será sobrescrito pelos flavors
        applicationId = "com.appTenda"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 1. Definir a dimensão
    flavorDimensions.add("client")

    // 2. Configurar os Product Flavors
    productFlavors {
        create("tucttx") {
            dimension = "client"
            applicationId = "com.appTenda"
        }

        create("tu7e") {
            dimension = "client"
            applicationId = "com.appTenda.tu7e"
        }

        create("tusva") {
            dimension = "client"
            applicationId = "com.appTenda.tusva"
        }
    }

    buildTypes {
        getByName("debug") {
            // Permite instalar o app de DEV junto com o de PROD no mesmo celular
            applicationIdSuffix = ".dev"
            signingConfig = signingConfigs.getByName("debug")
        }
        
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // 3. Lógica para definir o Nome do App dinamicamente por Flavor e BuildType
    applicationVariants.all {
        val variantName = name // ex: tucttxDebug
        val flavorName = flavorName.uppercase() // ex: TUCTTX
        
        if (variantName.contains("debug", ignoreCase = true)) {
            resValue("string", "app_name", "[DEV] $flavorName")
        } else {
            resValue("string", "app_name", flavorName)
        }
    }
}

flutter {
    source = "../.."
}