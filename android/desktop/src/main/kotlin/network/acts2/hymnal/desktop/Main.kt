package network.acts2.hymnal.desktop

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.core.LyricsTextSize
import network.acts2.hymnal.data.Settings
import network.acts2.hymnal.handleShortcut
import network.acts2.hymnal.ui.AppRoot
import network.acts2.hymnal.ui.theme.HymnalTheme
import org.jetbrains.compose.resources.decodeToImageBitmap
import java.awt.Dimension
import java.io.File
import java.util.prefs.Preferences

fun main() {
    val settings = Settings(PreferencesStore(Preferences.userRoot().node("network/acts2/hymnal")))
    val repository = FileHymnRepository(contentDir())
    val playback = JavaFxPlayback(settings, repository)
    val vm = HymnalViewModel(settings, repository, playback, version = System.getProperty("hymnal.version") ?: "dev")

    application {
        val icon = remember {
            BitmapPainter(object {}.javaClass.getResourceAsStream("/icon.png")!!.use { it.readBytes() }.decodeToImageBitmap())
        }
        val dark = when (settings.appearance) {
            "light" -> false
            "dark" -> true
            else -> isSystemInDarkTheme()
        }
        Window(
            onCloseRequest = {
                playback.close()
                exitApplication()
            },
            title = "A2N Hymnal",
            icon = icon,
            state = rememberWindowState(size = DpSize(1100.dp, 760.dp)),
            onPreviewKeyEvent = { event -> handleDesktopKey(vm, event) || vm.handleShortcut(event) },
        ) {
            // The same as the Mac app's minimum, so the list and lyrics always fit side by side.
            window.minimumSize = Dimension(760, 520)
            HymnalTheme(dark = dark) {
                AppRoot(vm)
            }
        }
    }
}

/**
 * The installed hymns and recordings: the app's resources folder once installed (and under
 * `./gradlew :desktop:run`), else the repo's content/ folder.
 */
private fun contentDir(): File =
    System.getProperty("compose.application.resources.dir")?.let(::File)?.takeIf { it.resolve("hymns").isDirectory }
        ?: File("../../content").absoluteFile

/**
 * Keys only the desktop has: Esc leaves Settings (like its Done button), and Ctrl+= / Ctrl+- /
 * Ctrl+0 make the lyrics bigger, smaller or the default size, like the Mac's View menu.
 */
private fun handleDesktopKey(vm: HymnalViewModel, event: KeyEvent): Boolean {
    if (event.type != KeyEventType.KeyDown) return false
    val settings = vm.settings
    when {
        event.key == Key.Escape && vm.showSettings -> vm.showSettings = false
        event.isCtrlPressed && (event.key == Key.Equals || event.key == Key.Plus || event.key == Key.NumPadAdd) ->
            settings.lyricsTextSizeStep = LyricsTextSize.clamped(settings.lyricsTextSizeStep + 1)
        event.isCtrlPressed && (event.key == Key.Minus || event.key == Key.NumPadSubtract) ->
            settings.lyricsTextSizeStep = LyricsTextSize.clamped(settings.lyricsTextSizeStep - 1)
        event.isCtrlPressed && (event.key == Key.Zero || event.key == Key.NumPad0) ->
            settings.lyricsTextSizeStep = LyricsTextSize.DEFAULT_STEP
        else -> return false
    }
    return true
}
