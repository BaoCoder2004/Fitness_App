plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "yourname.example.fitnessapp"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "yourname.example.fitnessapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Task to copy APK to Flutter's expected location
tasks.register("copyApkToFlutterOutput") {
    doLast {
        // Flutter project root is two levels up from android/app
        val flutterProjectRoot = rootProject.projectDir.parentFile
        val apkDir = file("${flutterProjectRoot}/build/app/outputs/flutter-apk")
        apkDir.mkdirs()
        
        // Copy release APK
        val releaseApk = file("build/outputs/apk/release/app-release.apk")
        if (releaseApk.exists()) {
            copy {
                from(releaseApk)
                into(apkDir)
            }
            println("Copied release APK to ${apkDir.absolutePath}")
        }
        
        // Copy debug APK
        val debugApk = file("build/outputs/apk/debug/app-debug.apk")
        if (debugApk.exists()) {
            copy {
                from(debugApk)
                into(apkDir)
            }
            println("Copied debug APK to ${apkDir.absolutePath}")
        }
    }
}

// Make copyApkToFlutterOutput run after assemble tasks
afterEvaluate {
    tasks.named("assembleRelease") {
        finalizedBy("copyApkToFlutterOutput")
    }
    
    tasks.named("assembleDebug") {
        finalizedBy("copyApkToFlutterOutput")
    }
}
