plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

// The hymns and recordings live in ../content, shared with the Apple app. Symlinks put them
// in the APK's assets as hymns/<locale>/<name>.txt and music/<name>.mp3, the same paths the
// Apple app's bundle uses, with the mp3s stored as they are, at full quality:
//   src/main/assets/hymns   → content/hymns  (every build)
//   src/debug/assets/music  → content/music  (debug APKs, so installDebug plays)
//   :music asset pack       → content/music  (release bundles; see music/build.gradle.kts)

// The Play upload key, kept out of the repo. Set these in ~/.gradle/gradle.properties;
// without them, release builds are unsigned.
val uploadStoreFile = providers.gradleProperty("A2N_HYMNAL_UPLOAD_STORE_FILE").orNull

android {
    namespace = "network.acts2.hymnal"
    compileSdk = 36

    defaultConfig {
        applicationId = "network.acts2.hymnal"
        minSdk = 26
        targetSdk = 36
        // Set in gradle.properties, shared with the desktop app.
        versionName = providers.gradleProperty("hymnal.versionName").get()
        versionCode = providers.gradleProperty("hymnal.versionCode").get().toInt()
    }

    assetPacks += ":music"

    signingConfigs {
        if (uploadStoreFile != null) {
            create("upload") {
                storeFile = file(uploadStoreFile)
                storePassword = providers.gradleProperty("A2N_HYMNAL_UPLOAD_STORE_PASSWORD").get()
                keyAlias = providers.gradleProperty("A2N_HYMNAL_UPLOAD_KEY_ALIAS").get()
                keyPassword = providers.gradleProperty("A2N_HYMNAL_UPLOAD_KEY_PASSWORD").get()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    androidResources {
        noCompress += "mp3"
    }
}

dependencies {
    // The screens and rules, shared with the desktop app.
    implementation(project(":shared"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons)
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.session)
    debugImplementation(libs.compose.ui.tooling)
}
