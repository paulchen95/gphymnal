package network.acts2.hymnal.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.QueueMusic
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.min
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.ui.theme.Brand

/**
 * List and lyrics side by side when the window is wide and landscape (tablets, and large
 * phones sideways), as on iPad; otherwise one page at a time, the lyrics pushed over the list.
 */
@Composable
fun AppRoot(vm: HymnalViewModel) {
    val listState = rememberLazyListState()

    if (vm.showSettings) {
        BackHandler { vm.showSettings = false }
        SettingsScreen(vm, onDone = { vm.showSettings = false })
        return
    }

    BoxWithConstraints(Modifier.fillMaxSize().background(Brand.colors.paper)) {
        val split = maxWidth >= 600.dp && maxWidth > maxHeight
        val listWidth = min(400.dp, maxWidth * 0.4f)
        if (split) {
            Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) {
                    HymnListPane(vm, listState, split = true)
                }
                VerticalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                Box(Modifier.weight(1f).fillMaxHeight()) {
                    val hymn = vm.selectedHymn
                    Scaffold(
                        containerColor = Brand.colors.paper,
                        bottomBar = { MiniPlayerArea(vm, pageHymn = hymn) },
                    ) { padding ->
                        if (hymn != null) {
                            LyricsPane(vm, hymn, split = true, contentPadding = padding)
                        } else {
                            NoHymnSelected(Modifier.padding(padding))
                        }
                    }
                }
            }
        } else {
            BackHandler(enabled = vm.selected != null) { vm.selected = null }
            AnimatedContent(
                targetState = vm.selectedHymn,
                contentKey = { it?.filename },
                transitionSpec = {
                    if (targetState != null) {
                        slideInHorizontally { it } togetherWith fadeOut()
                    } else {
                        fadeIn() togetherWith slideOutHorizontally { it }
                    }
                },
                label = "page",
            ) { hymn ->
                if (hymn == null) {
                    HymnListPane(vm, listState, split = false)
                } else {
                    Scaffold(
                        containerColor = Brand.colors.paper,
                        bottomBar = { MiniPlayerArea(vm, pageHymn = hymn) },
                    ) { padding ->
                        LyricsPane(vm, hymn, split = false, contentPadding = padding)
                    }
                }
            }
        }
    }
}

@Composable
private fun NoHymnSelected(modifier: Modifier = Modifier) {
    Column(
        modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.AutoMirrored.Rounded.QueueMusic, null, Modifier.size(48.dp), tint = Brand.colors.secondary)
        Text("Choose a Hymn", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Text(
            "Pick a hymn from the list to see its lyrics.",
            style = MaterialTheme.typography.bodyMedium,
            color = Brand.colors.secondary,
            textAlign = TextAlign.Center,
        )
    }
}
