package network.acts2.hymnal.desktop

import network.acts2.hymnal.data.SettingsStore
import java.util.prefs.Preferences

/** The desktop [SettingsStore]: `java.util.prefs`, which is the registry on Windows. */
class PreferencesStore(private val prefs: Preferences) : SettingsStore {
    override fun getBoolean(key: String) = prefs.get(key, null)?.toBooleanStrictOrNull()
    override fun getString(key: String): String? = prefs.get(key, null)
    override fun getInt(key: String) = prefs.get(key, null)?.toIntOrNull()
    /** Saved one per line: filenames never contain a newline. */
    override fun getStringSet(key: String) = prefs.get(key, null)?.split('\n')?.filter { it.isNotEmpty() }?.toSet()

    override fun putBoolean(key: String, value: Boolean) = save { prefs.putBoolean(key, value) }
    override fun putString(key: String, value: String?) = save { if (value == null) prefs.remove(key) else prefs.put(key, value) }
    override fun putInt(key: String, value: Int) = save { prefs.putInt(key, value) }
    override fun putStringSet(key: String, value: Set<String>) = save { prefs.put(key, value.sorted().joinToString("\n")) }

    private fun save(write: () -> Unit) {
        write()
        prefs.flush()
    }
}
