package network.acts2.hymnal.core

/**
 * Parses the hymn file format (`content/FORMAT.md`), the same way the Apple app's
 * `HymnList.formatHymn` does: split on `---`, then each part that starts with `key::` sets
 * that attribute. A one-colon `key:` matches nothing and is dropped. `fixtures/parsing.json`
 * pins the details.
 */
object HymnParser {
    /** Turns a title into Latin script without accents (pinyin for Chinese). */
    fun interface Latinizer {
        fun latinize(text: String): String
    }

    /** The ICU transform behind [Latinizer]: Apple's `.toLatin` then `.stripDiacritics`. */
    const val LATIN_TRANSFORM = "Any-Latin; NFD; [:Nonspacing Mark:] Remove; NFC"

    private val keys = listOf("name", "author", "translator", "composer", "arranger", "tune", "collection", "text")

    fun parse(fileContent: String, filename: String, locale: String = "en-us", latinizer: Latinizer = Latinizer { it }): Hymn {
        val values = mutableMapOf<String, String>()
        for (part in fileContent.split("---")) {
            val key = keys.firstOrNull { part.replace("\n", "").startsWith("$it::") } ?: continue
            val raw = part.split("::")[1]
            values[key] = if (key == "text") raw.trimSpaces() else raw.replace("\n", "").trimSpaces()
        }
        val name = values["name"].orEmpty()
        return Hymn(
            name = name,
            filename = filename,
            author = values["author"].orEmpty(),
            translator = values["translator"].orEmpty(),
            composer = values["composer"].orEmpty(),
            arranger = values["arranger"].orEmpty(),
            tune = values["tune"].orEmpty(),
            text = values["text"].orEmpty(),
            collection = values["collection"].orEmpty().ifEmpty { Hymn.DEFAULT_COLLECTION },
            locale = locale.ifEmpty { "en-us" },
            sortKey = latinizer.latinize(name),
        )
    }

    /** Trims spaces and tabs but not newlines, like Swift's `.whitespaces`: `text::` keeps its leading newline. */
    private fun String.trimSpaces() = trim { it.isWhitespace() && it != '\n' && it != '\r' }
}
