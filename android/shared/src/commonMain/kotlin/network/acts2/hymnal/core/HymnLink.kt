package network.acts2.hymnal.core

import java.net.URI

/**
 * Links that open a hymn in the app. A hymn's slug is its filename in kebab case
 * ("AmazingGrace" → "amazing-grace"). Two forms open the same hymn:
 *   a2nhymnal://hymn/amazing-grace           (custom scheme; only works with the app installed)
 *   https://<web host>/hymn/amazing-grace    (app link, once the web host is set up)
 * `?play=1` also starts the recording. `fixtures/links.json`.
 */
object HymnLink {
    const val SCHEME = "a2nhymnal"

    /** Share is hidden until the web links are live, as on Apple. */
    const val IS_SHARING_ENABLED = false

    data class Target(val slug: String, val play: Boolean)

    fun slug(filename: String): String = buildString {
        filename.forEachIndexed { index, c ->
            if (c.isUpperCase() && index > 0) append('-')
            append(c.lowercaseChar())
        }
    }

    fun appUrl(hymn: Hymn, play: Boolean = false): String =
        "$SCHEME://hymn/${slug(hymn.filename)}" + if (play) "?play=1" else ""

    /** The hymn slug and play flag in a link, if it's one of ours. */
    fun parse(url: String): Target? {
        val uri = runCatching { URI(url) }.getOrNull() ?: return null
        val play = uri.rawQuery.orEmpty().split('&').any {
            val (k, v) = it.split('=', limit = 2).let { p -> p[0] to p.getOrElse(1) { "" } }
            k == "play" && v != "0"
        }
        var parts = uri.path.orEmpty().split('/').filter { it.isNotEmpty() }
        when (uri.scheme) {
            SCHEME -> if (uri.host != "hymn") return null
            "https" -> {
                if (parts.size < 2 || parts[parts.size - 2] !in setOf("hymn", "hymnal")) return null
                parts = listOf(parts.last())
            }
            else -> return null
        }
        val slug = parts.lastOrNull()?.takeIf { it.isNotEmpty() } ?: return null
        return Target(slug, play)
    }

    /** The hymn a slug refers to, ignoring case and punctuation. */
    fun find(slug: String, hymns: List<Hymn>): Hymn? {
        fun key(s: String) = s.lowercase().filter { it.isLetterOrDigit() }
        val target = key(slug)
        return hymns.firstOrNull { key(it.filename) == target }
    }
}
