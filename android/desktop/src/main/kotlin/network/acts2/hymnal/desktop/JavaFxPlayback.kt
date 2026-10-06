package network.acts2.hymnal.desktop

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import javafx.application.Platform
import javafx.scene.media.Media
import javafx.scene.media.MediaPlayer
import javafx.util.Duration
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.data.Settings
import network.acts2.hymnal.playback.Playback

/**
 * The app-wide [Playback] on JavaFX's media player, which plays MP3 with Windows' own
 * decoders. JavaFX calls back on its own thread, so each callback hops to the UI thread
 * before touching state.
 */
class JavaFxPlayback(private val settings: Settings, private val repository: FileHymnRepository) : Playback {
    override var hymn by mutableStateOf<Hymn?>(null)
        private set
    override var isPlaying by mutableStateOf(false)
        private set
    override var position by mutableLongStateOf(0)
        private set
    override var duration by mutableLongStateOf(0)
        private set
    override var volume by mutableFloatStateOf(1f)
        private set

    override var repeats: Boolean
        get() = settings.repeatHymn
        set(value) {
            settings.repeatHymn = value
        }

    private var player: MediaPlayer? = null
    private val scope = MainScope()
    private var ticker: Job? = null

    init {
        startJavaFx()
    }

    override fun play(hymn: Hymn) {
        player?.dispose()
        this.hymn = hymn
        position = 0
        duration = 0
        val media = Media(repository.recording(hymn).toURI().toString())
        val player = MediaPlayer(media)
        this.player = player
        player.volume = volume.toDouble()
        player.setOnReady { onUi(player) { duration = media.duration.toMillis().toLong() } }
        player.setOnPlaying { onUi(player) { playingChanged(true) } }
        player.setOnPaused { onUi(player) { playingChanged(false) } }
        player.setOnStopped { onUi(player) { playingChanged(false) } }
        // At the end, rewind and wait, like the Apple app: the mini player stays up.
        player.setOnEndOfMedia {
            onUi(player) {
                player.seek(Duration.ZERO)
                if (repeats) player.play() else player.pause()
                position = 0
                // Only a real stop, as on Apple and Android, where a repeating hymn never ends.
                if (!repeats) Analytics.track(AnalyticsEvent.hymnFinished(hymn.filename, settings.hymnLocale))
            }
        }
        player.play()
    }

    override fun toggle() {
        val player = player ?: return
        if (isPlaying) player.pause() else player.play()
    }

    override fun seek(toMs: Long) {
        val target = toMs.coerceIn(0, duration.coerceAtLeast(0))
        player?.seek(Duration.millis(target.toDouble()))
        position = target
    }

    override fun restart() {
        seek(0)
        player?.play()
    }

    override fun changeVolume(by: Float) {
        volume = (volume + by).coerceIn(0f, 1f)
        player?.volume = volume.toDouble()
    }

    override fun close() {
        player?.dispose()
        player = null
        ticker?.cancel()
        hymn = null
        isPlaying = false
        position = 0
        duration = 0
    }

    private fun playingChanged(playing: Boolean) {
        isPlaying = playing
        ticker?.cancel()
        if (playing) {
            ticker = scope.launch {
                while (isActive) {
                    player?.let { position = it.currentTime.toMillis().toLong().coerceAtLeast(0) }
                    delay(250)
                }
            }
        }
        player?.let { position = it.currentTime.toMillis().toLong().coerceAtLeast(0) }
    }

    /** Runs [block] on the UI thread, unless [from] has since been replaced by another hymn. */
    private fun onUi(from: MediaPlayer, block: () -> Unit) {
        scope.launch { if (player === from) block() }
    }

    private companion object {
        /** JavaFX's media player needs its toolkit running, though it shows no JavaFX windows. */
        fun startJavaFx() {
            try {
                Platform.startup {}
            } catch (_: IllegalStateException) {
                // Already running.
            }
            Platform.setImplicitExit(false)
        }
    }
}
