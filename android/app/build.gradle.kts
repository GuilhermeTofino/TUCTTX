import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    // id("com.google.gms.google-services")
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
        isCoreLibraryDesugaringEnabled = true
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

    // Carregar configurações de assinatura do arquivo key.properties
    val keyProperties = Properties()
    val keyPropertiesFile = rootProject.file("key.properties")
    if (keyPropertiesFile.exists()) {
        keyProperties.load(keyPropertiesFile.inputStream())
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        getByName("release") {
            // Em vez de usar a config de debug, usamos a config de release definida acima
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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

    sourceSets {
        getByName("tucttxDev") { res.srcDirs("src/tucttx/res") }
        getByName("tucttxProd") { res.srcDirs("src/tucttx/res") }
        
        getByName("tu7eDev") { res.srcDirs("src/tu7e/res") }
        getByName("tu7eProd") { res.srcDirs("src/tu7e/res") }
        
        getByName("tusvaDev") { res.srcDirs("src/tusva/res") }
        getByName("tusvaProd") { res.srcDirs("src/tusva/res") }
    }
}



flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}