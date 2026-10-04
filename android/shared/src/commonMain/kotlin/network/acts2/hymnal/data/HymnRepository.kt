package network.acts2.hymnal.data

import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnParser

/**
 * The hymns and recordings bundled with the app (`hymns/<locale>/<name>.txt`,
 * `music/<name>.mp3`), copied there from `content/` at build time. Nothing is downloaded.
 * Each app says where its bundle is and how to read it: APK assets on Android, the
 * installed app's resources folder on the desktop.
 */
abstract class HymnRepository {
    /** The file names (not paths) in a bundle folder, e.g. `hymns/en-us`. */
    protected abstract fun list(folder: String): List<String>

    protected abstract fun readText(path: String): String

    /** Titles in Latin script, for ordering and the A–Z index (pinyin for Chinese). */
    protected abstract val latinizer: HymnParser.Latinizer

    /** Length of a recording in milliseconds without loading it for playback; 0 if there isn't one. */
    abstract fun duration(hymn: Hymn): Long

    /** Filenames that have a recording. */
    val recordings: Set<String> by lazy {
        list("music").filter { it.endsWith(".mp3") }.map { it.removeSuffix(".mp3") }.toSet()
    }

    fun hasAudio(hymn: Hymn): Boolean = hymn.filename in recordings

    /** Every hymn in [locale], sorted by title. Slow-ish: call off the main thread. */
    fun load(locale: String): List<Hymn> =
        list("hymns/$locale").filter { it.endsWith(".txt") }.map { file ->
            HymnParser.parse(readText("hymns/$locale/$file"), file.removeSuffix(".txt"), locale, latinizer)
        }.sortedBy { it.name }
}
