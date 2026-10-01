plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

// The hymns and recordings live in ../content, shared with the Apple app, and go into the
// APK's assets as hymns/<locale>/<name>.txt and music/<name>.mp3 — the same paths the Apple
// app's bundle uses. MP3s are stored uncompressed, at their original quality.
val contentDir = rootProject.file("../content")

android {
    namespace = "network.acts2.hymnal"
    compileSdk = 36

    defaultConfig {
        applicationId = "network.acts2.hymnal"
        minSdk = 26
        targetSdk = 36
        // Same as the Apple app's MARKETING_VERSION; versionCode is the date.
        versionName = "5.4.0"
        versionCode = 20260930
    }

    sourceSets["main"].assets.srcDir(contentDir)
    // The JVM tests read the shared fixtures and the real hymn files.
    sourceSets["test"].resources.srcDir(contentDir.resolve("fixtures"))

    buildTypes {
        release {
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
        // Leave out the docs and test fixtures in content/ (and the usual hidden files).
        ignoreAssetsPattern = "!fixtures:!*.md:!.*:!*~"
    }
    testOptions {
        unitTests.all {
            it.systemProperty("contentDir", contentDir.absolutePath)
        }
    }
}

dependencies {
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

    testImplementation(libs.junit)
    testImplementation(libs.json)
    // The app uses Android's built-in ICU for pinyin; the JVM tests need their own copy.
    testImplementation(libs.icu4j)
}
