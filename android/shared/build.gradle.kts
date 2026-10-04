plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.compose.multiplatform)
}

// Everything the Android app and the desktop (Windows) app have in common: the rules shared
// with Apple (core/), settings, the screens (ui/) and what they show (HymnalViewModel).
// Each app supplies its own hymn loading and player; see Playback and HymnRepository.
val contentDir = rootProject.file("../content")

kotlin {
    androidTarget {
        compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
    }
    jvm("desktop") {
        compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
    }

    sourceSets {
        commonMain.dependencies {
            api(compose.runtime)
            api(compose.foundation)
            api(compose.material3)
            api(compose.ui)
            api(compose.components.resources)
            api(libs.cmp.material.icons)
            api(libs.cmp.lifecycle.viewmodel)
        }
        androidMain.dependencies {
            implementation(libs.androidx.activity.compose)
        }
        val desktopTest by getting {
            dependencies {
                implementation(libs.junit)
                implementation(libs.json)
                implementation(libs.icu4j)
            }
        }
    }
}

android {
    namespace = "network.acts2.hymnal.shared"
    compileSdk = 36
    defaultConfig {
        minSdk = 26
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

compose.resources {
    publicResClass = true
    packageOfResClass = "network.acts2.hymnal.resources"
    generateResClass = always
}

// The JVM tests read the shared fixtures and the real hymn files.
tasks.named<Test>("desktopTest") {
    systemProperty("contentDir", contentDir.absolutePath)
}
kotlin.sourceSets.named("desktopTest") { resources.srcDir(contentDir.resolve("fixtures")) }
