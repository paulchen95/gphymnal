package network.acts2.hymnal

import android.app.Application
import android.content.ComponentName
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import network.acts2.hymnal.data.HymnRepository
import network.acts2.hymnal.data.Settings
import network.acts2.hymnal.playback.Playback
import network.acts2.hymnal.playback.PlaybackService

/** App-wide objects: settings, the bundled hymns, and the one player that keeps going while you browse. */
class HymnalApp : Application() {
    lateinit var settings: Settings
        private set
    lateinit var repository: HymnRepository
        private set
    lateinit var playback: Playback
        private set

    private var controller: ListenableFuture<MediaController>? = null

    override fun onCreate() {
        super.onCreate()
        settings = Settings(this)
        repository = HymnRepository(assets)
        playback = Playback(this, settings)
        // Stay connected to the playback service so it can keep playing in the background
        // and show its notification and lock-screen controls.
        controller = MediaController.Builder(this, SessionToken(this, ComponentName(this, PlaybackService::class.java))).buildAsync()
    }
}
