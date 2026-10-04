package network.acts2.hymnal.ui

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.FormatQuote
import androidx.compose.material.icons.rounded.MusicNote
import androidx.compose.material.icons.rounded.PauseCircle
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.PlayCircle
import androidx.compose.material.icons.rounded.RepeatOne
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.RestartAlt
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.playback.Playback
import network.acts2.hymnal.ui.theme.Brand

/**
 * The player pinned to the bottom of a page, as in the Apple app's `MiniPlayerInset`:
 *  - a hymn is loaded → the mini player, plus "Play '…' instead" if this page is another hymn;
 *  - nothing loaded, on a hymn page → that hymn, ready to play.
 */
@Composable
fun MiniPlayerArea(vm: HymnalViewModel, pageHymn: Hymn?) {
    val playback = vm.playback
    val loaded = playback.hymn
    val playablePage = pageHymn?.takeIf(vm::hasAudio)
    Column(
        Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .animateContentSize()
            .padding(horizontal = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (loaded != null) {
            if (playablePage != null && playablePage.filename != loaded.filename) {
                PlayInsteadButton(playablePage) { vm.play(playablePage) }
            }
            MiniPlayer(playback, loaded, onShowLyrics = { vm.selected = loaded.filename })
        } else if (playablePage != null) {
            ReadyToPlayBar(vm, playablePage)
        }
        if (loaded != null || playablePage != null) Spacer(Modifier.height(6.dp))
    }
}

@Composable
private fun BarSurface(modifier: Modifier = Modifier, shape: RoundedCornerShape = RoundedCornerShape(20.dp), content: @Composable () -> Unit) {
    Surface(
        modifier.widthIn(max = 640.dp),
        shape = shape,
        color = Brand.colors.surface,
        contentColor = Brand.colors.ink,
        shadowElevation = 8.dp,
        content = content,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MiniPlayer(playback: Playback, hymn: Hymn, onShowLyrics: () -> Unit) {
    var showNowPlaying by remember { mutableStateOf(false) }
    var scrub by remember { mutableStateOf<Long?>(null) }
    val position = scrub ?: playback.position

    BarSurface(Modifier.fillMaxWidth()) {
        Column {
            Row(
                Modifier.padding(start = 10.dp, end = 8.dp, top = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    Modifier
                        .weight(1f)
                        .clickable(onClickLabel = "Show playback controls") { showNowPlaying = true },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    HymnCover(hymn, full = false, modifier = Modifier.size(40.dp))
                    Spacer(Modifier.size(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(hymn.name, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(
                            formatTime(position) + " / " + formatTime(playback.duration),
                            fontSize = 12.sp,
                            color = Brand.colors.secondary,
                            style = Tabular,
                        )
                    }
                }
                PlayPauseButton(playback, 40.dp)
                // Once paused, the mini player can be put away.
                if (!playback.isPlaying) {
                    IconButton(onClick = playback::close) {
                        Icon(Icons.Rounded.Close, contentDescription = "Close Player", tint = Brand.colors.secondary)
                    }
                }
            }
            // A slim timeline along the bottom: tap or drag it to move through the hymn
            // without leaving the lyrics.
            PlaybackTimeline(
                position = position,
                duration = playback.duration,
                onScrub = { scrub = it },
                onCommit = {
                    playback.seek(it)
                    scrub = null
                },
                compact = true,
                modifier = Modifier.padding(horizontal = 14.dp).padding(bottom = 2.dp),
            )
        }
    }

    if (showNowPlaying) {
        ModalBottomSheet(
            onDismissRequest = { showNowPlaying = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            // The top of Now Playing's gold wash, so the handle strip blends in.
            containerColor = lerp(Brand.colors.paper, Brand.colors.accent, 0.18f),
        ) {
            NowPlaying(playback, hymn, onShowLyrics = {
                showNowPlaying = false
                onShowLyrics()
            })
        }
    }
}

/** The player bar on a hymn page when nothing is loaded. Tapping anywhere on it plays. */
@Composable
private fun ReadyToPlayBar(vm: HymnalViewModel, hymn: Hymn) {
    var duration by remember(hymn.filename) { mutableLongStateOf(0) }
    LaunchedEffect(hymn.filename) {
        duration = withContext(Dispatchers.IO) { vm.repository.duration(hymn) }
    }
    BarSurface(Modifier.fillMaxWidth()) {
        Row(
            Modifier
                .clickable(onClickLabel = "Play ${hymn.name}") { vm.play(hymn) }
                .padding(start = 10.dp, end = 14.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            HymnCover(hymn, full = false, modifier = Modifier.size(40.dp))
            Spacer(Modifier.size(12.dp))
            Column(Modifier.weight(1f)) {
                Text(hymn.name, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(
                    if (duration > 0) formatTime(duration) else " ",
                    fontSize = 12.sp,
                    color = Brand.colors.secondary,
                    style = Tabular,
                )
            }
            Icon(Icons.Rounded.PlayCircle, contentDescription = null, Modifier.size(40.dp), tint = Brand.colors.accent)
        }
    }
}

@Composable
private fun PlayInsteadButton(hymn: Hymn, play: () -> Unit) {
    BarSurface(Modifier.padding(horizontal = 12.dp), shape = RoundedCornerShape(50)) {
        Row(
            Modifier
                .clickable(onClick = play)
                .padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Rounded.PlayArrow, null, Modifier.size(18.dp), tint = Brand.colors.accent)
            Spacer(Modifier.size(6.dp))
            Text(
                "Play “${hymn.name}” instead",
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = Brand.colors.accent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun PlayPauseButton(playback: Playback, size: Dp) {
    IconButton(onClick = playback::toggle, modifier = Modifier.size(size + 8.dp)) {
        Icon(
            if (playback.isPlaying) Icons.Rounded.PauseCircle else Icons.Rounded.PlayCircle,
            contentDescription = if (playback.isPlaying) "Pause" else "Play",
            modifier = Modifier.size(size),
            tint = Brand.colors.accent,
        )
    }
}

/** Stands in for album art: the title and opening line on a warm gold gradient. */
@Composable
fun HymnCover(hymn: Hymn, full: Boolean, modifier: Modifier = Modifier) {
    val radius = if (full) 24.dp else 8.dp
    Box(
        modifier
            .shadow(if (full) 24.dp else 0.dp, RoundedCornerShape(radius))
            .clip(RoundedCornerShape(radius))
            .background(Brush.linearGradient(Brand.coverGradient)),
    ) {
        if (full) {
            Icon(
                Icons.Rounded.MusicNote, null,
                Modifier
                    .align(Alignment.TopEnd)
                    .offset(x = 30.dp, y = (-20).dp)
                    .size(220.dp)
                    .rotate(-12f),
                tint = Color.White.copy(alpha = 0.10f),
            )
            Column(Modifier.align(Alignment.BottomStart).padding(24.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "“${hymn.firstLine}”",
                    fontFamily = FontFamily.Serif,
                    fontStyle = FontStyle.Italic,
                    fontSize = 20.sp,
                    color = Color.White.copy(alpha = 0.9f),
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    hymn.name,
                    fontFamily = Brand.titleFont,
                    fontSize = 30.sp,
                    lineHeight = 34.sp,
                    color = Color.White,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        } else {
            Icon(Icons.Rounded.MusicNote, null, Modifier.align(Alignment.Center).size(24.dp), tint = Color.White.copy(alpha = 0.9f))
        }
    }
}

/**
 * Now Playing: cover card, title, timeline, transport, and Start Over / Repeat / View Lyrics.
 * On a short, wide screen (a phone in landscape) the cover sits beside the rest, as on iPhone.
 */
@Composable
private fun NowPlaying(playback: Playback, hymn: Hymn, onShowLyrics: () -> Unit) {
    var scrub by remember { mutableStateOf<Long?>(null) }
    val position = scrub ?: playback.position
    val coverScale by animateFloatAsState(if (playback.isPlaying) 1f else 0.92f, label = "cover")
    val wash = Brush.verticalGradient(listOf(lerp(Brand.colors.paper, Brand.colors.accent, 0.18f), Brand.colors.paper))

    val details: @Composable ColumnScope.() -> Unit = {
        Column(Modifier.fillMaxWidth()) {
            Text(hymn.name, fontFamily = Brand.titleFont, fontSize = 24.sp, lineHeight = 28.sp, maxLines = 2)
            if (hymn.author.isNotEmpty()) {
                Text(hymn.author, color = Brand.colors.secondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        Spacer(Modifier.height(16.dp))
        PlaybackTimeline(
            position = position,
            duration = playback.duration,
            onScrub = { scrub = it },
            onCommit = {
                playback.seek(it)
                scrub = null
            },
        )
        Row(Modifier.fillMaxWidth()) {
            Text(formatTime(position), fontSize = 12.sp, color = Brand.colors.secondary, style = Tabular)
            Spacer(Modifier.weight(1f))
            Text("-" + formatTime(playback.duration - position), fontSize = 12.sp, color = Brand.colors.secondary, style = Tabular)
        }
        Row(
            Modifier.padding(top = 12.dp).align(Alignment.CenterHorizontally),
            horizontalArrangement = Arrangement.spacedBy(40.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SkipButton(forward = false) { playback.skip(-15) }
            PlayPauseButton(playback, 72.dp)
            SkipButton(forward = true) { playback.skip(15) }
        }
        Spacer(Modifier.height(20.dp))
        NowPlayingFooter(playback, onShowLyrics)
    }

    BoxWithConstraints(Modifier.fillMaxWidth().background(wash)) {
        val coverMax = (maxHeight - 32.dp).coerceAtLeast(120.dp)
        if (maxWidth > maxHeight && maxHeight < 480.dp) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(32.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.weight(0.4f), contentAlignment = Alignment.Center) {
                    HymnCover(
                        hymn, full = true,
                        modifier = Modifier
                            .heightIn(max = coverMax)
                            .widthIn(max = 360.dp)
                            .aspectRatio(1f, matchHeightConstraintsFirst = true)
                            .scale(coverScale),
                    )
                }
                Column(Modifier.weight(0.6f), content = details)
            }
        } else {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                HymnCover(
                    hymn, full = true,
                    modifier = Modifier
                        .padding(top = 12.dp)
                        // Shrinks on short screens so the controls below always fit.
                        .weight(1f, fill = false)
                        .widthIn(max = 360.dp)
                        .aspectRatio(1f, matchHeightConstraintsFirst = true)
                        .scale(coverScale),
                )
                Spacer(Modifier.height(28.dp))
                details()
            }
        }
    }
}

/** Start Over, Repeat and View Lyrics along the bottom of Now Playing. */
@Composable
private fun NowPlayingFooter(playback: Playback, onShowLyrics: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        TextButton(onClick = playback::restart) {
            Icon(Icons.Rounded.RestartAlt, null, Modifier.size(20.dp))
            Spacer(Modifier.size(6.dp))
            Text("Start Over", fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.weight(1f))
        IconButton(
            onClick = { playback.repeats = !playback.repeats },
            modifier = Modifier.semantics { stateDescription = if (playback.repeats) "On" else "Off" },
        ) {
            Box(
                Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(if (playback.repeats) Brand.colors.accent else Color.Transparent),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Rounded.RepeatOne,
                    contentDescription = "Repeat",
                    tint = if (playback.repeats) Brand.colors.onAccent else Brand.colors.secondary,
                )
            }
        }
        Spacer(Modifier.weight(1f))
        TextButton(onClick = onShowLyrics) {
            Icon(Icons.Rounded.FormatQuote, null, Modifier.size(20.dp))
            Spacer(Modifier.size(6.dp))
            Text("View Lyrics", fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun SkipButton(forward: Boolean, onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier.size(56.dp)) {
        Box(contentAlignment = Alignment.Center) {
            Icon(
                Icons.Rounded.Replay,
                contentDescription = if (forward) "Forward 15 Seconds" else "Back 15 Seconds",
                modifier = Modifier
                    .size(40.dp)
                    .graphicsLayer { if (forward) scaleX = -1f },
                tint = Brand.colors.ink,
            )
            Text("15", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Brand.colors.ink, modifier = Modifier.offset(y = 2.dp))
        }
    }
}

/**
 * The timeline, as in Apple Music: tap anywhere on it to jump there, or drag to scrub, inside
 * a tall touch area that's easy to hit with a finger.
 *
 * It previews where you'd land the way Spotify's desktop player does. With a mouse over it the
 * track thickens and brightens, a knob marks the playback position, a lighter band runs from
 * there to the pointer, and a bubble above the pointer shows the time a click would jump to. A
 * finger gets the knob and the bubble while it's down.
 */
@Composable
private fun PlaybackTimeline(
    position: Long,
    duration: Long,
    onScrub: (Long) -> Unit,
    onCommit: (Long) -> Unit,
    /** The slim version in the mini player. */
    compact: Boolean = false,
    modifier: Modifier = Modifier,
) {
    /** Where a finger or a pressed mouse is, along the track, in px; null otherwise. */
    var dragX by remember { mutableStateOf<Float?>(null) }
    /** Where a hovering mouse is, along the track, in px; null otherwise. */
    var hoverX by remember { mutableStateOf<Float?>(null) }
    val touching = dragX != null
    val active = touching || hoverX != null
    val height by animateDpAsState(
        when {
            compact -> if (touching) 8.dp else if (hoverX != null) 5.dp else 3.dp
            else -> if (touching) 12.dp else if (hoverX != null) 8.dp else 6.dp
        },
        label = "track",
    )
    val fraction = if (duration > 0) (position.toFloat() / duration).coerceIn(0f, 1f) else 0f
    val scrub by rememberUpdatedState(onScrub)
    val commit by rememberUpdatedState(onCommit)
    val length by rememberUpdatedState(duration)

    BoxWithConstraints(
        modifier
            .fillMaxWidth()
            .height(if (compact) 22.dp else 32.dp)
            .semantics { contentDescription = "Playback position ${formatTime(position)}" }
            .pointerInput(Unit) {
                fun timeAt(x: Float) = ((x / size.width).coerceIn(0f, 1f) * length).toLong()
                awaitEachGesture {
                    val down = awaitFirstDown()
                    var x = down.position.x
                    dragX = x
                    scrub(timeAt(x))
                    drag(down.id) { change ->
                        change.consume()
                        x = change.position.x
                        dragX = x
                        scrub(timeAt(x))
                    }
                    dragX = null
                    commit(timeAt(x))
                }
            }
            // A mouse's hover, seen before the drag handler consumes anything.
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent(PointerEventPass.Initial)
                        val change = event.changes.firstOrNull() ?: continue
                        if (change.type != PointerType.Mouse) continue
                        hoverX = when (event.type) {
                            PointerEventType.Exit -> null
                            else -> change.position.x
                        }
                    }
                }
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        val width = constraints.maxWidth.toFloat()
        val progressX = width * fraction
        val density = LocalDensity.current
        Box(
            Modifier
                .fillMaxWidth()
                .height(height)
                .clip(CircleShape)
                .background(Brand.colors.ink.copy(alpha = if (active) 0.22f else 0.15f)),
        ) {
            val pointer = hoverX?.coerceIn(0f, width)
            // The stretch a click would skip over: ahead of the playback position it fills in
            // lightly; behind it, it lightens the gold.
            if (pointer != null && !touching && pointer > progressX) {
                Box(Modifier.width(with(density) { pointer.toDp() }).fillMaxHeight().background(Brand.colors.accent.copy(alpha = 0.35f)))
            }
            Box(
                Modifier
                    .fillMaxWidth(fraction)
                    .fillMaxHeight()
                    .clip(CircleShape)
                    .background(Brand.colors.accent.copy(alpha = if (active) 1f else 0.85f)),
            )
            if (pointer != null && !touching && pointer < progressX) {
                Box(
                    Modifier
                        .offset { IntOffset(pointer.roundToInt(), 0) }
                        .width(with(density) { (progressX - pointer).toDp() })
                        .fillMaxHeight()
                        .background(Color.White.copy(alpha = 0.45f)),
                )
            }
        }
        if (active) {
            val knob = if (compact) 12.dp else 16.dp
            Box(
                Modifier
                    .offset { IntOffset((progressX - knob.toPx() / 2).roundToInt(), 0) }
                    .size(knob)
                    .shadow(2.dp, CircleShape)
                    .background(Color.White, CircleShape),
            )
        }
        val bubbleAt = dragX ?: hoverX
        if (bubbleAt != null) {
            val pointerX = bubbleAt.coerceIn(0f, width)
            // Clear of the knob for a mouse; well clear of the fingertip for touch.
            val gap = if (hoverX != null) 6.dp else 26.dp
            TimeBubble(
                formatTime(((pointerX / width).coerceIn(0f, 1f) * duration).toLong()),
                Modifier.layout { measurable, _ ->
                    val bubble = measurable.measure(Constraints())
                    // Laid out at the track's centre line with no size of its own, so it draws
                    // above the track without pushing anything around. Centred over the
                    // pointer, but kept within the track's ends.
                    layout(0, 0) {
                        val x = (pointerX - bubble.width / 2f).coerceIn(0f, (width - bubble.width).coerceAtLeast(0f))
                        val y = -(bubble.height + gap.toPx() + height.toPx() / 2)
                        bubble.place(x.roundToInt(), y.roundToInt())
                    }
                },
            )
        }
    }
}

/** The small dark label over the timeline showing the time you'd jump to; dark in both themes. */
@Composable
private fun TimeBubble(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        modifier
            .clearAndSetSemantics {}
            .shadow(4.dp, RoundedCornerShape(6.dp))
            .background(Color(0xFF292929), RoundedCornerShape(6.dp))
            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(6.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        color = Color.White,
        fontSize = 12.sp,
        fontWeight = FontWeight.SemiBold,
        style = Tabular,
    )
}

/** Digits of equal width, so the times don't jiggle as they count. */
private val Tabular = TextStyle(fontFeatureSettings = "tnum")

/** m:ss */
fun formatTime(ms: Long): String {
    val seconds = (ms.coerceAtLeast(0) / 1000).toInt()
    return "%d:%02d".format(seconds / 60, seconds % 60)
}
