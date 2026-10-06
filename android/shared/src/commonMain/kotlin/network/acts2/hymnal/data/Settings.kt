package network.acts2.hymnal.data

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.core.LyricsTextSize
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

/**
 * Where settings are saved: SharedPreferences on Android, `java.util.prefs` on the desktop.
 * Absent keys return null.
 */
interface SettingsStore {
    fun getBoolean(key: String): Boolean?
    fun getString(key: String): String?
    fun getInt(key: String): Int?
    fun getStringSet(key: String): Set<String>?
    fun putBoolean(key: String, value: Boolean)
    /** Null removes the key. */
    fun putString(key: String, value: String?)
    fun putInt(key: String, value: Int)
    fun putStringSet(key: String, value: Set<String>)
}

/**
 * Saved settings, as Compose state. The keys match the Apple app's `@AppStorage` keys. A
 * change is tracked here, whichever screen or shortcut made it (see `ANALYTICS.md`).
 */
class Settings(prefs: SettingsStore) {

    var showChristmas by prefs.boolean("showChristmasHymns", true) { AnalyticsEvent.settingChanged("christmas_hymns", it) }
    var hymnLocale by prefs.string("hymnLocale", "en-us") { AnalyticsEvent.settingChanged("language", it) }
    var enableSearchHighlighting by prefs.boolean("enableSearchHighlighting", true) {
        AnalyticsEvent.settingChanged("search_highlighting", it)
    }
    var lyricsTextSizeStep by prefs.int(LyricsTextSize.STORAGE_KEY, LyricsTextSize.DEFAULT_STEP) {
        AnalyticsEvent.settingChanged("text_size", LyricsTextSize.percent(it))
    }
    var repeatHymn by prefs.boolean("repeatHymn", false) { AnalyticsEvent.repeatToggled(it) }
    /** "system", "light" or "dark". */
    var appearance by prefs.string("appearance", "system") { AnalyticsEvent.settingChanged("appearance", it) }

    /** Starred hymns by filename, for the Favorites section; on this device only. */
    var favorites by prefs.stringSet("favoriteHymns")

    /** The hymn whose lyrics were open last, so the app reopens on it; null for the list. */
    var lastOpenHymn by prefs.nullableString("lastOpenHymn")

    fun toggleFavorite(filename: String) {
        val starred = filename in favorites
        favorites = if (starred) favorites - filename else favorites + filename
        Analytics.track(if (starred) AnalyticsEvent.favoriteRemoved(filename) else AnalyticsEvent.favoriteAdded(filename))
    }
}

/** A saved setting. [tracked] is the analytics event for a change, if it has one. */
private class Pref<T>(
    initial: T,
    private val tracked: ((T) -> AnalyticsEvent)? = null,
    private val write: (T) -> Unit,
) : ReadWriteProperty<Any, T> {
    private val state: MutableState<T> = mutableStateOf(initial)
    override fun getValue(thisRef: Any, property: KProperty<*>): T = state.value
    override fun setValue(thisRef: Any, property: KProperty<*>, value: T) {
        val changed = value != state.value
        state.value = value
        write(value)
        if (changed) tracked?.let { Analytics.track(it(value)) }
    }
}

private fun SettingsStore.boolean(key: String, default: Boolean, tracked: ((Boolean) -> AnalyticsEvent)? = null): ReadWriteProperty<Any, Boolean> =
    Pref(getBoolean(key) ?: default, tracked) { putBoolean(key, it) }

private fun SettingsStore.string(key: String, default: String, tracked: ((String) -> AnalyticsEvent)? = null): ReadWriteProperty<Any, String> =
    Pref(getString(key) ?: default, tracked) { putString(key, it) }

private fun SettingsStore.nullableString(key: String): ReadWriteProperty<Any, String?> =
    Pref(getString(key)) { putString(key, it) }

private fun SettingsStore.int(key: String, default: Int, tracked: ((Int) -> AnalyticsEvent)? = null): ReadWriteProperty<Any, Int> =
    Pref(getInt(key) ?: default, tracked) { putInt(key, it) }

private fun SettingsStore.stringSet(key: String): ReadWriteProperty<Any, Set<String>> =
    Pref(getStringSet(key) ?: emptySet()) { putStringSet(key, it) }
