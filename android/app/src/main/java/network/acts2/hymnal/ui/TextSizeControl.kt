package network.acts2.hymnal.ui

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.TextDecrease
import androidx.compose.material.icons.rounded.TextIncrease
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import network.acts2.hymnal.core.LyricsTextSize

/** Smaller / percent / larger, on the lyrics page and in Settings (the same saved value). */
@Composable
fun TextSizeControl(step: Int, onChange: (Int) -> Unit, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = { onChange(LyricsTextSize.clamped(step - 1)) }, enabled = step > 0) {
            Icon(Icons.Rounded.TextDecrease, contentDescription = "Smaller Text")
        }
        Text(
            "${LyricsTextSize.percent(step)}%",
            Modifier.widthIn(min = 52.dp),
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.SemiBold,
        )
        IconButton(
            onClick = { onChange(LyricsTextSize.clamped(step + 1)) },
            enabled = step < LyricsTextSize.multipliers.lastIndex,
        ) {
            Icon(Icons.Rounded.TextIncrease, contentDescription = "Larger Text")
        }
    }
}
