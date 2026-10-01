package network.acts2.hymnal

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.LaunchedEffect
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import network.acts2.hymnal.core.HymnLink
import network.acts2.hymnal.ui.AppRoot
import network.acts2.hymnal.ui.theme.HymnalTheme

class MainActivity : ComponentActivity() {
    private val viewModel: HymnalViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) handleLink(intent)
        setContent {
            val dark = when (viewModel.settings.appearance) {
                "light" -> false
                "dark" -> true
                else -> isSystemInDarkTheme()
            }
            // Status and navigation bar icons follow the app's appearance, not the system's.
            LaunchedEffect(dark) {
                val style = if (dark) SystemBarStyle.dark(Color.TRANSPARENT)
                else SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
                enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
            }
            HymnalTheme(dark = dark) {
                AppRoot(viewModel)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleLink(intent)
    }

    private fun handleLink(intent: Intent?) {
        val url = intent?.dataString ?: return
        HymnLink.parse(url)?.let(viewModel::open)
    }

    /**
     * Hardware-keyboard shortcuts, the same as the Mac app's (Spotify's), with Ctrl for ⌘.
     * Off while typing in search, where Space, Return and the arrows belong to the field.
     */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN && handleShortcut(event)) return true
        return super.dispatchKeyEvent(event)
    }

    private fun handleShortcut(event: KeyEvent): Boolean {
        val vm = viewModel
        val playback = vm.playback
        val ctrl = event.isCtrlPressed
        val shift = event.isShiftPressed
        if (ctrl && event.keyCode == KeyEvent.KEYCODE_F) {
            vm.showSettings = false
            vm.focusSearchRequest++
            return true
        }
        if (vm.searchFocused || vm.showSettings) return false
        when {
            !ctrl && event.keyCode == KeyEvent.KEYCODE_SPACE -> vm.playPause()
            !ctrl && event.keyCode == KeyEvent.KEYCODE_ENTER -> {
                if (vm.selectedHymn == null) return false
                vm.playSelected()
            }
            ctrl && shift && event.keyCode == KeyEvent.KEYCODE_DPAD_RIGHT -> playback.skip(15)
            ctrl && shift && event.keyCode == KeyEvent.KEYCODE_DPAD_LEFT -> playback.skip(-15)
            ctrl && event.keyCode == KeyEvent.KEYCODE_DPAD_RIGHT -> vm.next()
            ctrl && event.keyCode == KeyEvent.KEYCODE_DPAD_LEFT -> vm.previous()
            ctrl && event.keyCode == KeyEvent.KEYCODE_DPAD_UP -> playback.changeVolume(0.1f)
            ctrl && event.keyCode == KeyEvent.KEYCODE_DPAD_DOWN -> playback.changeVolume(-0.1f)
            ctrl && event.keyCode == KeyEvent.KEYCODE_R -> playback.repeats = !playback.repeats
            else -> return false
        }
        return true
    }
}
