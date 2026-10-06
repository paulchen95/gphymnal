package network.acts2.hymnal

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.LaunchedEffect
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.core.HymnLink
import network.acts2.hymnal.ui.AppRoot
import network.acts2.hymnal.ui.theme.HymnalTheme

class MainActivity : ComponentActivity() {
    private val viewModel: HymnalViewModel by viewModels {
        viewModelFactory {
            initializer {
                val app = application as HymnalApp
                HymnalViewModel(
                    app.settings, app.repository, app.playback,
                    version = "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                )
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            Analytics.track(AnalyticsEvent.appOpened())
            handleLink(intent)
        }
        setContent {
            val dark = when (viewModel.settings.appearance) {
                "light" -> false
                "dark" -> true
                else -> isSystemInDarkTheme()
            }
            // Status and navigation bar icons follow the app's appearance, not the system's.
            LaunchedEffect(dark) {
                val style = if (dark) SystemBarStyle.dark(Color.TRANSPARENT)
                else SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
                enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
            }
            HymnalTheme(dark = dark) {
                AppRoot(viewModel)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleLink(intent)
    }

    private fun handleLink(intent: Intent?) {
        val url = intent?.dataString ?: return
        HymnLink.parse(url)?.let(viewModel::open)
    }

    /** Hardware-keyboard shortcuts (`Shortcuts.kt`), the same as the Mac app's with Ctrl for ⌘. */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (viewModel.handleShortcut(androidx.compose.ui.input.key.KeyEvent(event))) return true
        return super.dispatchKeyEvent(event)
    }
}
