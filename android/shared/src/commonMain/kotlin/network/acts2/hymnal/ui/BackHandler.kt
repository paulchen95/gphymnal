package network.acts2.hymnal.ui

import androidx.compose.runtime.Composable

/** The system Back gesture or button on Android. The desktop has none (Esc is a shortcut there). */
@Composable
expect fun BackHandler(enabled: Boolean = true, onBack: () -> Unit)
