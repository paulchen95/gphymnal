package network.acts2.hymnal.data

import android.content.res.AssetManager
import android.icu.text.Transliterator
import android.media.MediaMetadataRetriever
import android.os.Build
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnParser
import java.text.Normalizer

/**
 * The hymns and recordings bundled in the APK's assets (`hymns/<locale>/<name>.txt`,
 * `music/<name>.mp3`), copied there from `content/` at build time. Nothing is downloaded.
 */
class HymnRepository(private val assets: AssetManager) {
    /** Filenames that have a recording. */
    val recordings: Set<String> by lazy {
        assets.list("music").orEmpty().filter { it.endsWith(".mp3") }.map { it.removeSuffix(".mp3") }.toSet()
    }

    fun hasAudio(hymn: Hymn): Boolean = hymn.filename in recordings

    /** Every hymn in [locale], sorted by title. Slow-ish: call off the main thread. */
    fun load(locale: String): List<Hymn> =
        assets.list("hymns/$locale").orEmpty().filter { it.endsWith(".txt") }.map { file ->
            val text = assets.open("hymns/$locale/$file").bufferedReader().use { it.readText() }
            HymnParser.parse(text, file.removeSuffix(".txt"), locale, AndroidLatinizer)
        }.sortedBy { it.name }

    /** Length of a recording in milliseconds without loading it for playback; 0 if there isn't one. */
    fun duration(hymn: Hymn): Long {
        if (!hasAudio(hymn)) return 0
        return runCatching {
            assets.openFd("music/${hymn.filename}.mp3").use { fd ->
                MediaMetadataRetriever().run {
                    try {
                        setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                        extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
                    } finally {
                        release()
                    }
                }
            }
        }.getOrDefault(0)
    }
}

/**
 * Titles in Latin script without accents, for ordering and the A–Z index (pinyin for
 * Chinese). Android's ICU has the transform from Android 10; before that only accents are
 * removed, so Chinese titles file under "#".
 */
private object AndroidLatinizer : HymnParser.Latinizer {
    private val transliterator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) Transliterator.getInstance(HymnParser.LATIN_TRANSFORM) else null

    override fun latinize(text: String): String =
        transliterator?.transliterate(text)
            ?: Normalizer.normalize(text, Normalizer.Form.NFD).replace(Regex("\\p{Mn}+"), "")
}
