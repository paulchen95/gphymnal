package network.acts2.hymnal.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.FormatSize
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.StarOutline
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextIndent
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.LyricStyle
import network.acts2.hymnal.core.LyricsTextSize
import network.acts2.hymnal.ui.theme.Brand

/**
 * A hymn's lyrics, set like a printed hymnal: the title in the page, wrapped lines indented
 * under their first line, a gap between sung lines, and the credits underneath. Lyrics fade
 * out under the top bar and the player.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LyricsPane(vm: HymnalViewModel, hymn: Hymn, split: Boolean, contentPadding: PaddingValues) {
    val step = vm.settings.lyricsTextSizeStep
    val colors = Brand.colors

    Column(Modifier.fillMaxSize().padding(contentPadding)) {
        TopAppBar(
            title = {},
            navigationIcon = {
                if (!split) {
                    IconButton(onClick = { vm.selected = null }) {
                        Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = "Hymns")
                    }
                }
            },
            actions = {
                val starred = hymn.filename in vm.settings.favorites
                IconButton(onClick = { vm.settings.toggleFavorite(hymn.filename) }) {
                    Icon(
                        if (starred) Icons.Rounded.Star else Icons.Rounded.StarOutline,
                        contentDescription = if (starred) "Remove from Favorites" else "Add to Favorites",
                    )
                }
                TextSizeButton(step) { vm.settings.lyricsTextSizeStep = it }
                CopyButton(hymn)
            },
            // Ink outline icons, as on iPhone and the Mac.
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = colors.paper,
                        navigationIconContentColor = colors.ink,
                        actionIconContentColor = colors.ink,
                    ),
            // The Scaffold's padding already clears the status bar.
            windowInsets = WindowInsets(0),
        )

        // A new hymn, or a new text size, starts at the top with the title in view.
        key(hymn.filename) {
            val scroll = rememberScrollState()
            LaunchedEffect(step) { scroll.scrollTo(0) }
            val currentStep by rememberUpdatedState(step)
            Box(
                Modifier
                    .fillMaxSize()
                    .pinchToResize { delta ->
                        vm.settings.lyricsTextSizeStep = LyricsTextSize.clamped(currentStep + delta)
                    }
            ) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(scroll)
                        .padding(top = TOP_FADE + 4.dp, bottom = BOTTOM_FADE),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Column(
                        Modifier
                            .widthIn(max = 640.dp)
                            .fillMaxWidth()
                            .padding(horizontal = if (split) 56.dp else 24.dp)
                    ) {
                        Text(
                            hymn.name,
                            fontFamily = Brand.titleFont,
                            fontSize = 34.sp,
                            lineHeight = 38.sp,
                            color = colors.ink,
                        )
                        Spacer(Modifier.height(12.dp))
                        Lyrics(hymn, step, vm.highlightQuery)
                        Credits(hymn)
                    }
                }
                Fade(Modifier.align(Alignment.TopCenter), TOP_FADE, top = true)
                Fade(Modifier.align(Alignment.BottomCenter), BOTTOM_FADE, top = false)
            }
        }
    }
}

private val TOP_FADE = 24.dp
private val BOTTOM_FADE = 64.dp

@Composable
private fun Fade(modifier: Modifier, height: androidx.compose.ui.unit.Dp, top: Boolean) {
    val paper = Brand.colors.paper
    val stops = if (top) listOf(paper, paper.copy(alpha = 0f)) else listOf(paper.copy(alpha = 0f), paper)
    Box(modifier.fillMaxWidth().height(height).background(Brush.verticalGradient(stops)))
}

@Composable
private fun Lyrics(hymn: Hymn, step: Int, highlight: String) {
    val density = LocalDensity.current
    // The fixture's size is in on-screen points, already scaled by the system font size.
    val size = (LyricsTextSize.pointSize(step, density.fontScale) / density.fontScale).sp
    val ink = Brand.colors.ink
    val base = TextStyle(
        fontSize = size,
        lineHeight = size * 1.3f,
        color = ink,
        // Wrapped lines hang under the first, so each sung line stays distinct.
        textIndent = TextIndent(firstLine = 0.sp, restLine = size * 1.2f),
    )
    val gap = with(density) { (size * 0.45f).toDp() }
    val verseGap = with(density) { (size * 1.3f).toDp() }

    for (line in hymn.lyricLines) {
        if (line.isBreak) {
            Spacer(Modifier.height(verseGap))
            continue
        }
        Text(
            highlighted(line.text, highlight),
            Modifier.padding(bottom = gap),
            style = base.copy(
                fontWeight = if (line.style == LyricStyle.Refrain) FontWeight.Bold else null,
                fontStyle = if (line.style != LyricStyle.Plain) FontStyle.Italic else null,
            ),
        )
    }
}

/** The search text in red wherever it appears, ignoring case. */
private fun highlighted(text: String, query: String): AnnotatedString = buildAnnotatedString {
    append(text)
    if (query.isBlank()) return@buildAnnotatedString
    var from = 0
    while (true) {
        val i = text.indexOf(query, from, ignoreCase = true)
        if (i < 0) break
        addStyle(SpanStyle(color = Color(0xFFE5484D)), i, i + query.length)
        from = i + query.length
    }
}

@Composable
private fun Credits(hymn: Hymn) {
    val credits = hymn.credits
    if (credits.isEmpty()) return
    Spacer(Modifier.height(24.dp))
    for ((label, value) in credits) {
        Text("$label: $value", fontSize = 14.sp, lineHeight = 20.sp, color = Brand.colors.secondary)
    }
}

@Composable
private fun TextSizeButton(step: Int, onChange: (Int) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { open = true }) {
            Icon(Icons.Rounded.FormatSize, contentDescription = "Text Size")
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            TextSizeControl(step, onChange, Modifier.padding(horizontal = 12.dp))
        }
    }
}

@Composable
private fun CopyButton(hymn: Hymn) {
    val clipboard = LocalClipboardManager.current
    val haptics = LocalHapticFeedback.current
    var copied by remember(hymn.filename) { mutableStateOf(false) }
    LaunchedEffect(copied) {
        if (copied) {
            delay(1500)
            copied = false
        }
    }
    IconButton(onClick = {
        clipboard.setText(AnnotatedString(hymn.plainText))
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        copied = true
    }) {
        Icon(
            if (copied) Icons.Rounded.Check else Icons.Rounded.ContentCopy,
            contentDescription = if (copied) "Copied" else "Copy Lyrics",
        )
    }
}

/**
 * Pinch to make the lyrics bigger or smaller, one text-size step at a time. The text
 * reflows (rather than zooming the page as on Apple), so lines never run off the screen.
 * Only two-finger gestures are taken; one finger still scrolls.
 */
private fun Modifier.pinchToResize(onStep: (Int) -> Unit): Modifier = pointerInput(Unit) {
    awaitEachGesture {
        awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
        var zoom = 1f
        do {
            val event = awaitPointerEvent(PointerEventPass.Initial)
            if (event.changes.count { it.pressed } >= 2) {
                zoom *= event.calculateZoom()
                if (zoom > 1.25f) {
                    onStep(1)
                    zoom = 1f
                } else if (zoom < 0.8f) {
                    onStep(-1)
                    zoom = 1f
                }
                event.changes.forEach { it.consume() }
            }
        } while (event.changes.any { it.pressed })
    }
}
