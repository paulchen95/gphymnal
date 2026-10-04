import org.jetbrains.compose.desktop.application.dsl.TargetFormat
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.compose.multiplatform)
}

// The Windows app: the shared screens (:shared) in a desktop window, with the hymns and
// recordings installed next to it, uncompressed and at full quality. Nothing is downloaded.
val versionName = providers.gradleProperty("hymnal.versionName").get()
val versionCode = providers.gradleProperty("hymnal.versionCode").get()

// Windows only installs an MSI over an older one when its version is higher, and it reads just
// major.minor.build. So the third number is a Windows build number, which CI sets to its run
// number (-Phymnal.windowsBuild=N): every test build installs over the last without touching
// the version Android and Apple share. Local builds use the patch number.
val (major, minor, patch) = versionName.split('.').map(String::toInt)
val windowsBuild = providers.gradleProperty("hymnal.windowsBuild").orNull
val windowsVersion = "$major.$minor.${windowsBuild ?: patch}"
/** Shown in Settings → About, so a tester can say which build they have. */
val displayVersion = if (windowsBuild != null) "$versionName (Windows build $windowsBuild)" else "$versionName ($versionCode)"

// JavaFX plays the recordings. Its jars carry native code, so pick the build machine's: a
// Windows installer is built on Windows (jpackage can't cross-build), and `run` works anywhere.
val javafxPlatform = System.getProperty("os.name").lowercase().let { os ->
    val arm = System.getProperty("os.arch") in setOf("aarch64", "arm64")
    when {
        "win" in os -> "win"
        "mac" in os -> if (arm) "mac-aarch64" else "mac"
        else -> if (arm) "linux-aarch64" else "linux"
    }
}

dependencies {
    implementation(project(":shared"))
    implementation(compose.desktop.currentOs)
    implementation(libs.kotlinx.coroutines.swing)
    // Pinyin for Chinese titles: the same ICU transform as Android and the tests.
    implementation(libs.icu4j)
    for (module in listOf("base", "graphics", "media")) {
        implementation("org.openjfx:javafx-$module:${libs.versions.javafx.get()}:$javafxPlatform")
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
}

// content/hymns and content/music, installed as the app's resources folder
// (`compose.application.resources.dir`), at the same hymns/ and music/ paths as the other apps.
val bundledContent = layout.buildDirectory.dir("content")
val copyContent by tasks.registering(Sync::class) {
    from(rootProject.file("../content")) {
        include("hymns/**", "music/**")
    }
    into(bundledContent.map { it.dir("common") })
}
tasks.matching { it.name == "prepareAppResources" }.configureEach { dependsOn(copyContent) }

compose.desktop {
    application {
        mainClass = "network.acts2.hymnal.desktop.MainKt"
        jvmArgs += listOf("-Dhymnal.version=$displayVersion")

        nativeDistributions {
            targetFormats(TargetFormat.Msi, TargetFormat.Exe)
            packageName = "A2N Hymnal"
            packageVersion = windowsVersion
            description = "A2N Hymnal"
            vendor = "Acts2 Network"
            appResourcesRootDir.set(bundledContent)
            // From ./gradlew :desktop:suggestRuntimeModules.
            modules("java.instrument", "java.prefs", "jdk.jfr", "jdk.unsupported")

            windows {
                iconFile.set(project.file("icons/hymnal.ico"))
                menuGroup = "A2N Hymnal"
                shortcut = true
                // Installs for the current user, so no administrator prompt.
                perUserInstall = true
                // Keeps updates installing over the previous version. Never change it.
                upgradeUuid = "6F1C2B9E-4E7A-4C3F-9C58-2D7A41E0B5A3"
            }
        }
    }
}
