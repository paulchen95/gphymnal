package network.acts2.hymnal.data

import android.content.Context
import androidx.core.content.edit

/** Android's [SettingsStore]: the app's "settings" SharedPreferences. */
class SharedPreferencesStore(context: Context) : SettingsStore {
    private val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    override fun getBoolean(key: String) = if (prefs.contains(key)) prefs.getBoolean(key, false) else null
    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun getInt(key: String) = if (prefs.contains(key)) prefs.getInt(key, 0) else null
    override fun getStringSet(key: String): Set<String>? = prefs.getStringSet(key, null)?.toSet()
    override fun putBoolean(key: String, value: Boolean) = prefs.edit { putBoolean(key, value) }
    override fun putString(key: String, value: String?) = prefs.edit { putString(key, value) }
    override fun putInt(key: String, value: Int) = prefs.edit { putInt(key, value) }
    override fun putStringSet(key: String, value: Set<String>) = prefs.edit { putStringSet(key, value) }
}
