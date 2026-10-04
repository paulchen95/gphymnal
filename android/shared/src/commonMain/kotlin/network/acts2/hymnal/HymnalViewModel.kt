package network.acts2.hymnal

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnLink
import network.acts2.hymnal.core.HymnSections
import network.acts2.hymnal.data.HymnRepository
import network.acts2.hymnal.data.Settings
import network.acts2.hymnal.playback.Playback

/**
 * What the screens show: the hymns, search, the open hymn, and Settings. The app supplies
 * the platform parts: saved settings, the bundled hymns, the player, and its version for About.
 */
class HymnalViewModel(
    val settings: Settings,
    val repository: HymnRepository,
    val playback: Playback,
    /** "5.4.0 (2026100102)", shown in Settings → About. */
    val version: String,
) : ViewModel() {
    var hymns by mutableStateOf<List<Hymn>>(emptyList())
        private set
    var query by mutableStateOf("")
    /**
     * The open hymn's filename, shared by the side-by-side and one-page layouts. Saved, so the
     * app reopens on the hymn that was open when it was last closed.
     */
    var selected by settings::lastOpenHymn
    var showSettings by mutableStateOf(false)
    /** The cursor is in the search field, so Space and Return belong to it. */
    var searchFocused by mutableStateOf(false)
    /** Bumped to ask the list to focus its search field (Ctrl+F). */
    var focusSearchRequest by mutableStateOf(0)
    /** The key of the shortcut just pressed, so its release is taken too (`Shortcuts.kt`). */
    internal var shortcutKeyDown: Key? = null

    val sections by derivedStateOf { HymnSections.visible(hymns, query, settings.showChristmas, settings.favorites) }
    val selectedHymn by derivedStateOf { hymns.firstOrNull { it.filename == selected } }
    /** The search text to highlight in the lyrics, if that setting is on. */
    val highlightQuery: String get() = if (settings.enableSearchHighlighting) query else ""

    private var pendingLink: HymnLink.Target? = null

    init {
        reload()
    }

    /** Re-reads the hymns, e.g. after the language changes. */
    fun reload() {
        val locale = settings.hymnLocale
        viewModelScope.launch {
            hymns = withContext(Dispatchers.IO) { repository.load(locale) }
            // The reopened hymn may be gone (removed, or not in this language): show the list.
            if (hymns.none { it.filename == selected }) selected = null
            pendingLink?.let { pendingLink = null; open(it) }
        }
    }

    fun hasAudio(hymn: Hymn) = repository.hasAudio(hymn)

    fun play(hymn: Hymn) {
        if (hasAudio(hymn)) playback.play(hymn)
    }

    /** Opens a hymn from a link, and plays it if the link says `?play=1`. */
    fun open(link: HymnLink.Target) {
        if (hymns.isEmpty()) {
            pendingLink = link
            return
        }
        val hymn = HymnLink.find(link.slug, hymns) ?: return
        showSettings = false
        selected = hymn.filename
        if (link.play) play(hymn)
    }

    /** Space: play/pause, or play the open hymn when nothing is loaded. */
    fun playPause() {
        if (playback.hymn != null) playback.toggle() else selectedHymn?.let(::play)
    }

    /** Return: play the hymn you're looking at, replacing whatever was playing. */
    fun playSelected() {
        selectedHymn?.let(::play)
    }

    /** Previous restarts the hymn unless it has only just begun, like Spotify. */
    fun previous() {
        if (playback.hymn != null && playback.position > 3000) playback.seek(0) else playNeighbour(-1)
    }

    fun next() = playNeighbour(1)

    /** Plays the hymn next to the current one in the list as it's shown, and opens it. */
    private fun playNeighbour(offset: Int) {
        // A–Z order only: a favourite is listed twice.
        val order = sections.filter { it.letter != HymnSections.FAVORITES_LETTER }.flatMap { it.hymns }.filter(::hasAudio)
        if (order.isEmpty()) return
        val current = playback.hymn?.filename ?: selected
        val index = order.indexOfFirst { it.filename == current }
        val target = if (index < 0) order.first() else order.getOrNull(index + offset) ?: return
        selected = target.filename
        play(target)
    }
}
