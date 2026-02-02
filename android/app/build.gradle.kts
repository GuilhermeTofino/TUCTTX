plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
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
        create("tucttxDev") {
            dimension = "client"
            applicationId = "com.appTenda.tucttx.dev"
        }
        create("tucttxProd") {
            dimension = "client"
            applicationId = "com.appTenda"
        }

        create("tu7eDev") {
            dimension = "client"
            applicationId = "com.appTenda.tu7e.dev"
        }
        create("tu7eProd") {
            dimension = "client"
            applicationId = "com.appTenda.tu7e"
        }

        create("tusvaDev") {
            dimension = "client"
            applicationId = "com.appTenda.tusva.dev"
        }
        create("tusvaProd") {
            dimension = "client"
            applicationId = "com.appTenda.tusva"
        }
    }

    buildTypes {
        getByName("debug") {
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
        val flavor = flavorName // ex: tucttxDev
        val isDev = flavor.contains("Dev")
        val baseName = flavor.replace("Dev", "").replace("Prod", "").uppercase()
        
        val displayName = if (isDev) "[DEV] $baseName" else baseName
        resValue("string", "app_name", displayName)
    }
}

flutter {
    source = "../.."
}