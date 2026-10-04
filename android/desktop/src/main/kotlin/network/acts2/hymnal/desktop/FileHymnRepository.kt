package network.acts2.hymnal.desktop

import com.ibm.icu.text.Transliterator
import javafx.scene.media.Media
import javafx.scene.media.MediaPlayer
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnParser
import network.acts2.hymnal.data.HymnRepository
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** The hymns and recordings installed with the app, as plain files under [root]. */
class FileHymnRepository(private val root: File) : HymnRepository() {
    override fun list(folder: String): List<String> = root.resolve(folder).list()?.toList().orEmpty()

    override fun readText(path: String): String = root.resolve(path).readText()

    override val latinizer = object : HymnParser.Latinizer {
        private val transliterator = Transliterator.getInstance(HymnParser.LATIN_TRANSFORM)
        override fun latinize(text: String): String = transliterator.transliterate(text)
    }

    /** JavaFX reads the length from the file's headers once the player is ready. Blocks briefly. */
    override fun duration(hymn: Hymn): Long {
        if (!hasAudio(hymn)) return 0
        return runCatching {
            val media = Media(recording(hymn).toURI().toString())
            val player = MediaPlayer(media)
            val ready = CountDownLatch(1)
            player.setOnReady { ready.countDown() }
            player.setOnError { ready.countDown() }
            try {
                if (ready.await(3, TimeUnit.SECONDS)) media.duration.toMillis().toLong().coerceAtLeast(0) else 0
            } finally {
                player.dispose()
            }
        }.getOrDefault(0)
    }

    fun recording(hymn: Hymn): File = root.resolve("music/${hymn.filename}.mp3")
}
