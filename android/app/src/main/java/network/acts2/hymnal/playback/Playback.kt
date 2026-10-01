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
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.data.Settings

/**
 * The one app-wide player (the Apple app's `NowPlaying` + `Mp3Player`): the loaded hymn
 * keeps playing while you browse. Its state is Compose state, so the mini player and Now
 * Playing redraw as it changes. `PlaybackService` wraps the same player in a media session
 * for background playback and the system controls.
 */
class Playback(context: Context, private val settings: Settings) {
    val player: ExoPlayer = ExoPlayer.Builder(context)
        .setAudioAttributes(
            AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
            /* handleAudioFocus = */ true,
        )
        .setHandleAudioBecomingNoisy(true)
        .build()

    /** The loaded hymn, or null when the player is closed. */
    var hymn by mutableStateOf<Hymn?>(null)
        private set
    var isPlaying by mutableStateOf(false)
        private set
    /** Milliseconds. */
    var position by mutableLongStateOf(0)
        private set
    var duration by mutableLongStateOf(0)
        private set
    var volume by mutableFloatStateOf(1f)
        private set

    var repeats: Boolean
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

    /** Loads [hymn] and plays it from the start, replacing whatever was loaded. */
    fun play(hymn: Hymn) {
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

    fun toggle() = if (player.isPlaying) player.pause() else player.play()

    fun seek(toMs: Long) {
        player.seekTo(toMs.coerceIn(0, duration.coerceAtLeast(0)))
        update()
    }

    fun skip(seconds: Int) = seek(player.currentPosition + seconds * 1000L)

    fun restart() {
        player.seekTo(0)
        player.play()
    }

    fun changeVolume(by: Float) {
        volume = (volume + by).coerceIn(0f, 1f)
        player.volume = volume
    }

    /** Puts the mini player away. */
    fun close() {
        player.stop()
        player.clearMediaItems()
        hymn = null
        position = 0
        duration = 0
    }
}
