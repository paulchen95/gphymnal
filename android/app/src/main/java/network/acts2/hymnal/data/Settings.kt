package network.acts2.hymnal.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.core.content.edit
import network.acts2.hymnal.core.LyricsTextSize
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

/** Saved settings, as Compose state. The keys match the Apple app's `@AppStorage` keys. */
class Settings(context: Context) {
    private val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    var showChristmas by prefs.boolean("showChristmasHymns", true)
    var hymnLocale by prefs.string("hymnLocale", "en-us")
    var enableSearchHighlighting by prefs.boolean("enableSearchHighlighting", true)
    var lyricsTextSizeStep by prefs.int(LyricsTextSize.STORAGE_KEY, LyricsTextSize.DEFAULT_STEP)
    var repeatHymn by prefs.boolean("repeatHymn", false)
    /** "system", "light" or "dark". */
    var appearance by prefs.string("appearance", "system")

    /** Starred hymns by filename, for the Favorites section; on this device only. */
    var favorites by prefs.stringSet("favoriteHymns")

    /** The hymn whose lyrics were open last, so the app reopens on it; null for the list. */
    var lastOpenHymn by prefs.nullableString("lastOpenHymn")

    fun toggleFavorite(filename: String) {
        favorites = if (filename in favorites) favorites - filename else favorites + filename
    }
}

private class Pref<T>(
    initial: T,
    private val write: (T) -> Unit,
) : ReadWriteProperty<Any, T> {
    private val state: MutableState<T> = mutableStateOf(initial)
    override fun getValue(thisRef: Any, property: KProperty<*>): T = state.value
    override fun setValue(thisRef: Any, property: KProperty<*>, value: T) {
        state.value = value
        write(value)
    }
}

private fun SharedPreferences.boolean(key: String, default: Boolean): ReadWriteProperty<Any, Boolean> =
    Pref(getBoolean(key, default)) { edit { putBoolean(key, it) } }

private fun SharedPreferences.string(key: String, default: String): ReadWriteProperty<Any, String> =
    Pref(getString(key, default) ?: default) { edit { putString(key, it) } }

private fun SharedPreferences.nullableString(key: String): ReadWriteProperty<Any, String?> =
    Pref(getString(key, null)) { edit { putString(key, it) } }

private fun SharedPreferences.int(key: String, default: Int): ReadWriteProperty<Any, Int> =
    Pref(getInt(key, default)) { edit { putInt(key, it) } }

private fun SharedPreferences.stringSet(key: String): ReadWriteProperty<Any, Set<String>> =
    Pref(getStringSet(key, emptySet())?.toSet() ?: emptySet()) { edit { putStringSet(key, it) } }
