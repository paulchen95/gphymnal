package network.acts2.hymnal.playback

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.data.Settings

/**
 * The app-wide [Playback] on Media3's ExoPlayer. `PlaybackService` wraps the same player in
 * a media session for background playback and the system controls.
 */
class ExoPlayback(context: Context, private val settings: Settings) : Playback {
    val player: ExoPlayer = ExoPlayer.Builder(context)
        .setAudioAttributes(
            AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
            /* handleAudioFocus = */ true,
        )
        .setHandleAudioBecomingNoisy(true)
        .build()

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
            player.repeatMode = if (value) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        }

    private val scope = MainScope()
    private var ticker: Job? = null

    init {
        player.repeatMode = if (repeats) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        player.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(playing: Boolean) {
                isPlaying = playing
                if (playing) startTicking() else ticker?.cancel()
                update()
            }

            override fun onPlaybackStateChanged(state: Int) {
                // At the end, rewind and wait, like the Apple app: the mini player stays up.
                if (state == Player.STATE_ENDED) {
                    player.pause()
                    player.seekTo(0)
                    hymn?.let { Analytics.track(AnalyticsEvent.hymnFinished(it.filename, settings.hymnLocale)) }
                }
                update()
            }

            override fun onPositionDiscontinuity(old: Player.PositionInfo, new: Player.PositionInfo, reason: Int) = update()
        })
    }

    private fun update() {
        position = player.currentPosition.coerceAtLeast(0)
        duration = player.duration.takeIf { it != C.TIME_UNSET } ?: 0
    }

    private fun startTicking() {
        ticker?.cancel()
        ticker = scope.launch {
            while (isActive) {
                update()
                delay(250)
            }
        }
    }

    override fun play(hymn: Hymn) {
        this.hymn = hymn
        val item = MediaItem.Builder()
            .setMediaId(hymn.filename)
            .setUri(Uri.parse("asset:///music/${hymn.filename}.mp3"))
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(hymn.name)
                    .setArtist(hymn.author.ifEmpty { null })
                    .setAlbumTitle("A2N Hymnal")
                    .build()
            )
            .build()
        player.setMediaItem(item)
        player.prepare()
        player.play()
        position = 0
    }

    override fun toggle() = if (player.isPlaying) player.pause() else player.play()

    override fun seek(toMs: Long) {
        player.seekTo(toMs.coerceIn(0, duration.coerceAtLeast(0)))
        update()
    }

    override fun skip(seconds: Int) = seek(player.currentPosition + seconds * 1000L)

    override fun restart() {
        player.seekTo(0)
        player.play()
    }

    override fun changeVolume(by: Float) {
        volume = (volume + by).coerceIn(0f, 1f)
        player.volume = volume
    }

    override fun close() {
        player.stop()
        player.clearMediaItems()
        hymn = null
        position = 0
        duration = 0
    }
}
