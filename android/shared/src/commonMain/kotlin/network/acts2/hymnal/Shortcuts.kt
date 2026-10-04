package network.acts2.hymnal

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type

/**
 * Keyboard shortcuts, the same as the Mac app's (Spotify's), with Ctrl for ⌘. Off while
 * typing in search, where Space, Return and the arrows belong to the field. Returns whether
 * the key was used. Android calls this for a hardware keyboard; the desktop for every key.
 */
fun HymnalViewModel.handleShortcut(event: KeyEvent): Boolean {
    // A shortcut takes its key's release too. Otherwise a focused button (the play button
    // you just clicked) presses itself on Space's release and undoes the play/pause.
    if (event.type == KeyEventType.KeyUp && event.key == shortcutKeyDown) {
        shortcutKeyDown = null
        return true
    }
    if (event.type != KeyEventType.KeyDown) return false
    if (!handleKeyDown(event)) return false
    shortcutKeyDown = event.key
    return true
}

private fun HymnalViewModel.handleKeyDown(event: KeyEvent): Boolean {
    val ctrl = event.isCtrlPressed
    val shift = event.isShiftPressed
    if (ctrl && event.key == Key.F) {
        showSettings = false
        focusSearchRequest++
        return true
    }
    if (searchFocused || showSettings) return false
    when {
        !ctrl && event.key == Key.Spacebar -> playPause()
        !ctrl && (event.key == Key.Enter || event.key == Key.NumPadEnter) -> {
            if (selectedHymn == null) return false
            playSelected()
        }
        ctrl && shift && event.key == Key.DirectionRight -> playback.skip(15)
        ctrl && shift && event.key == Key.DirectionLeft -> playback.skip(-15)
        ctrl && event.key == Key.DirectionRight -> next()
        ctrl && event.key == Key.DirectionLeft -> previous()
        ctrl && event.key == Key.DirectionUp -> playback.changeVolume(0.1f)
        ctrl && event.key == Key.DirectionDown -> playback.changeVolume(-0.1f)
        ctrl && event.key == Key.R -> playback.repeats = !playback.repeats
        else -> return false
    }
    return true
}
