package network.acts2.hymnal.data

import android.content.res.AssetManager
import android.icu.text.Transliterator
import android.media.MediaMetadataRetriever
import android.os.Build
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnParser
import java.text.Normalizer

/** The hymns and recordings in the APK's assets (and the `music` asset pack). */
class AssetHymnRepository(private val assets: AssetManager) : HymnRepository() {
    override fun list(folder: String): List<String> = assets.list(folder).orEmpty().toList()

    override fun readText(path: String): String = assets.open(path).bufferedReader().use { it.readText() }

    override val latinizer: HymnParser.Latinizer = AndroidLatinizer

    override fun duration(hymn: Hymn): Long {
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
