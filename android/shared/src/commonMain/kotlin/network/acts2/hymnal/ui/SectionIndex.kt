package network.acts2.hymnal.ui

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import network.acts2.hymnal.ui.theme.Brand

/**
 * The A–Z index down the right edge, as in Contacts: tap a letter or drag along it to jump.
 * The strip is 28dp wide and runs the whole height, so a finger finds it easily.
 */
@Composable
fun SectionIndex(letters: List<String>, onLetter: (String) -> Unit, modifier: Modifier = Modifier) {
    if (letters.size < 2) return
    val haptics = LocalHapticFeedback.current
    val currentLetters by rememberUpdatedState(letters)
    val currentOnLetter by rememberUpdatedState(onLetter)

    Column(
        modifier
            .fillMaxHeight()
            .width(28.dp)
            .padding(vertical = 8.dp)
            .semantics { contentDescription = "Section index" }
            .pointerInput(Unit) {
                var last: String? = null
                fun pick(y: Float) {
                    val list = currentLetters
                    val i = (y / size.height * list.size).toInt().coerceIn(0, list.lastIndex)
                    if (list[i] != last) {
                        last = list[i]
                        haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        currentOnLetter(list[i])
                    }
                }
                awaitEachGesture {
                    val down = awaitFirstDown()
                    last = null
                    pick(down.position.y)
                    drag(down.id) { change ->
                        change.consume()
                        pick(change.position.y)
                    }
                }
            },
        verticalArrangement = Arrangement.SpaceEvenly,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        BoxWithConstraints(Modifier.weight(1f)) {
            // On a short screen (a phone sideways), show some letters with dots between, as
            // iOS does. Dragging still reaches every letter.
            val slots = (maxHeight / 22.dp).toInt().coerceAtLeast(3)
            Column(
                Modifier.fillMaxHeight(),
                verticalArrangement = Arrangement.SpaceEvenly,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                for (label in condensed(letters, slots)) {
                    Text(label, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Brand.colors.accent)
                }
            }
        }
    }
}

/** [letters] fitted into [slots] rows: every letter if they fit, else first, last, and evenly spaced ones with "•" between. */
private fun condensed(letters: List<String>, slots: Int): List<String> {
    if (letters.size <= slots) return letters
    val shown = (slots + 1) / 2
    val picks = List(shown) { i -> letters[(i * letters.lastIndex) / (shown - 1).coerceAtLeast(1)] }.distinct()
    return picks.flatMapIndexed { i, letter -> if (i == 0) listOf(letter) else listOf("•", letter) }
}
