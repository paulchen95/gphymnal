package network.acts2.hymnal.core

/** A hymn language: its name in Settings and its credit labels. Each has a `content/hymns/<code>/` folder. */
data class HymnLocale(
    val name: String,
    val author: String,
    val translator: String,
    val composer: String,
    val arranger: String,
    val tune: String,
)

object Locales {
    val all = mapOf(
        "en-us" to HymnLocale("English", "Author", "Translator", "Composer", "Arranger", "Tune"),
        "zh-cn" to HymnLocale("Chinese (Simplified)", "作者", "翻译", "作曲家", "编曲者", "曲调"),
        "zh-tw" to HymnLocale("Chinese (Traditional)", "作者", "翻譯", "作曲家", "編曲者", "曲調"),
    )
}
