package network.acts2.hymnal.playback

import network.acts2.hymnal.core.Hymn

/**
 * The one app-wide player (the Apple app's `NowPlaying` + `Mp3Player`): the loaded hymn
 * keeps playing while you browse. Its properties are Compose state, so the mini player and
 * Now Playing redraw as they change. Android plays with Media3, the desktop with JavaFX.
 */
interface Playback {
    /** The loaded hymn, or null when the player is closed. */
    val hymn: Hymn?
    val isPlaying: Boolean
    /** Milliseconds. */
    val position: Long
    val duration: Long
    val volume: Float
    /** Loop the hymn; saved in Settings. */
    var repeats: Boolean

    /** Loads [hymn] and plays it from the start, replacing whatever was loaded. */
    fun play(hymn: Hymn)
    fun toggle()
    fun seek(toMs: Long)
    fun skip(seconds: Int) = seek(position + seconds * 1000L)
    fun restart()
    fun changeVolume(by: Float)
    /** Puts the mini player away. */
    fun close()
}
