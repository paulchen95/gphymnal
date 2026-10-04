package network.acts2.hymnal.core

/**
 * One hymn, parsed from `content/hymns/<locale>/<filename>.txt` (see `content/FORMAT.md`).
 * Plain Kotlin with no Android types, so the JVM tests can run the shared fixtures on it.
 */
data class Hymn(
    val name: String,
    /** The join key across locales and the recording: `music/<filename>.mp3`. */
    val filename: String,
    val author: String = "",
    val translator: String = "",
    val composer: String = "",
    val arranger: String = "",
    val tune: String = "",
    val text: String = "",
    val collection: String = DEFAULT_COLLECTION,
    val locale: String = "en-us",
    /** The title in Latin script without accents (pinyin for Chinese), for ordering and the index letter. */
    val sortKey: String = name,
) {
    val isChristmas: Boolean get() = collection == CHRISTMAS

    /**
     * The letter this hymn is listed under, as in Contacts: leading punctuation is skipped
     * ("'Tis So Sweet" is under T) and anything that doesn't start with A–Z is under "#".
     */
    val indexLetter: String
        get() {
            val first = sortKey.firstOrNull { it.isLetterOrDigit() } ?: return "#"
            val letter = first.uppercaseChar()
            return if (letter in 'A'..'Z') letter.toString() else "#"
        }

    /** Non-empty credits in display order, with labels in the hymn's language. */
    val credits: List<Pair<String, String>>
        get() {
            val labels = Locales.all[locale] ?: Locales.all.getValue("en-us")
            return listOf(
                labels.author to author,
                labels.translator to translator,
                labels.composer to composer,
                labels.arranger to arranger,
                labels.tune to tune,
            ).filter { it.second.isNotEmpty() }
        }

    /** The opening line of the lyrics, for the Now Playing card. */
    val firstLine: String
        get() = text.lines().map { it.trim() }.firstOrNull { it.isNotEmpty() && it !in MARKERS } ?: ""

    /** The hymn as plain text for copying: title, lyrics without the markers, then the credits. */
    val plainText: String
        get() {
            val lyrics = text.lines().filter { it !in MARKERS }.joinToString("\n").trim()
            val parts = mutableListOf(name, lyrics)
            if (credits.isNotEmpty()) parts += credits.joinToString("\n") { "${it.first}: ${it.second}" }
            return parts.joinToString("\n\n")
        }

    /** The lyrics as styled lines: `[Refrain]` lines bold italic, `[Tag]` lines italic, until a blank line. */
    val lyricLines: List<LyricLine>
        get() {
            var style = LyricStyle.Plain
            val result = mutableListOf<LyricLine>()
            for (line in text.lines()) {
                when (line) {
                    REFRAIN -> style = LyricStyle.Refrain
                    TAG -> style = LyricStyle.Tag
                    "" -> {
                        style = LyricStyle.Plain
                        result += LyricLine("", LyricStyle.Plain)
                    }
                    else -> result += LyricLine(line, style)
                }
            }
            return result
        }

    companion object {
        const val DEFAULT_COLLECTION = "Hymn"
        const val CHRISTMAS = "Christmas"
        /** Marks Christmas hymns in the list and labels the Christmas setting, so both match. */
        const val CHRISTMAS_MARKER = "🎄"
        const val REFRAIN = "[Refrain]"
        const val TAG = "[Tag]"
        private val MARKERS = setOf(REFRAIN, TAG)
    }
}

enum class LyricStyle { Plain, Refrain, Tag }

/** One sung line, or an empty line between verses. */
data class LyricLine(val text: String, val style: LyricStyle) {
    val isBreak: Boolean get() = text.isEmpty()
}
