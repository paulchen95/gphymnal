package network.acts2.hymnal.ui

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
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
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
    val progress = if (playback.duration > 0) playback.position.toFloat() / playback.duration else 0f

    BarSurface(Modifier.fillMaxWidth()) {
        Box {
            Row(
                Modifier.padding(start = 10.dp, end = 8.dp, top = 10.dp, bottom = 10.dp),
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
                            formatTime(playback.position) + " / " + formatTime(playback.duration),
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
            // Spotify-style hairline progress along the bottom edge.
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .padding(horizontal = 14.dp, vertical = 3.dp)
                    .fillMaxWidth()
                    .height(2.dp)
            ) {
                Box(
                    Modifier
                        .fillMaxWidth(progress.coerceIn(0f, 1f))
                        .fillMaxHeight()
                        .clip(CircleShape)
                        .background(Brand.colors.accent)
                )
            }
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

/** Now Playing: cover card, title, timeline, transport, and Start Over / Repeat / View Lyrics. */
@Composable
private fun NowPlaying(playback: Playback, hymn: Hymn, onShowLyrics: () -> Unit) {
    var scrub by remember { mutableStateOf<Long?>(null) }
    val position = scrub ?: playback.position
    val coverScale by animateFloatAsState(if (playback.isPlaying) 1f else 0.92f, label = "cover")

    Column(
        Modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(listOf(lerp(Brand.colors.paper, Brand.colors.accent, 0.18f), Brand.colors.paper)))
            .padding(horizontal = 28.dp)
            .padding(bottom = 24.dp),
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
            Modifier.padding(top = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(40.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SkipButton(forward = false) { playback.skip(-15) }
            PlayPauseButton(playback, 72.dp)
            SkipButton(forward = true) { playback.skip(15) }
        }
        Spacer(Modifier.height(20.dp))
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
 * The timeline, as in Apple Music: tap anywhere on it to jump there, or drag to scrub. The
 * track thickens while touched, inside a tall touch area that's easy to hit with a finger.
 */
@Composable
private fun PlaybackTimeline(position: Long, duration: Long, onScrub: (Long) -> Unit, onCommit: (Long) -> Unit) {
    var touching by remember { mutableStateOf(false) }
    val height by animateDpAsState(if (touching) 12.dp else 6.dp, label = "track")
    val fraction = if (duration > 0) (position.toFloat() / duration).coerceIn(0f, 1f) else 0f
    val scrub by rememberUpdatedState(onScrub)
    val commit by rememberUpdatedState(onCommit)
    val length by rememberUpdatedState(duration)

    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .height(32.dp)
            .semantics { contentDescription = "Playback position ${formatTime(position)}" }
            .pointerInput(Unit) {
                fun timeAt(x: Float) = ((x / size.width).coerceIn(0f, 1f) * length).toLong()
                awaitEachGesture {
                    val down = awaitFirstDown()
                    touching = true
                    var x = down.position.x
                    scrub(timeAt(x))
                    drag(down.id) { change ->
                        change.consume()
                        x = change.position.x
                        scrub(timeAt(x))
                    }
                    touching = false
                    commit(timeAt(x))
                }
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(Modifier.fillMaxWidth().height(height).clip(CircleShape).background(Brand.colors.ink.copy(alpha = 0.15f)))
        Box(Modifier.fillMaxWidth(fraction).height(height).clip(CircleShape).background(Brand.colors.accent))
    }
}

/** Digits of equal width, so the times don't jiggle as they count. */
private val Tabular = TextStyle(fontFeatureSettings = "tnum")

/** m:ss */
fun formatTime(ms: Long): String {
    val seconds = (ms.coerceAtLeast(0) / 1000).toInt()
    return "%d:%02d".format(seconds / 60, seconds % 60)
}
