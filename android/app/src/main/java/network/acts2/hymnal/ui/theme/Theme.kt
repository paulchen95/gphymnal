package network.acts2.hymnal.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import network.acts2.hymnal.R

/**
 * The Acts2 Network look, matching the Apple app's asset catalog: warm paper and ink,
 * a gold accent, and Clash Grotesk for large titles only.
 */
@Immutable
data class BrandColors(
    val paper: Color,
    val paperDeep: Color,
    val surface: Color,
    val ink: Color,
    val accent: Color,
    val onAccent: Color,
    val secondary: Color,
)

private val Light = BrandColors(
    paper = Color(0xFFF3F2F1),
    paperDeep = Color(0xFFE7E5E4),
    surface = Color(0xFFFFFFFF),
    ink = Color(0xFF1C1917),
    accent = Color(0xFF975A07),
    onAccent = Color(0xFFFFFFFF),
    secondary = Color(0xFF78716C),
)

private val Dark = BrandColors(
    paper = Color(0xFF1C1917),
    paperDeep = Color(0xFF292524),
    surface = Color(0xFF292524),
    ink = Color(0xFFF5F5F4),
    accent = Color(0xFFCA8A04),
    onAccent = Color(0xFF1C1917),
    secondary = Color(0xFFA8A29E),
)

val LocalBrand = staticCompositionLocalOf { Light }

object Brand {
    val colors: BrandColors @Composable get() = LocalBrand.current
    val titleFont = FontFamily(Font(R.font.clash_grotesk_semibold, FontWeight.SemiBold))
    /** The "album art" gradient on the Now Playing card. */
    val coverGradient = listOf(Color(0xFFDE991A), Color(0xFF8C4A0A))
}

@Composable
fun HymnalTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val brand = if (dark) Dark else Light
    val base = if (dark) darkColorScheme() else lightColorScheme()
    val scheme = base.copy(
        primary = brand.accent,
        onPrimary = brand.onAccent,
        secondary = brand.accent,
        onSecondary = brand.onAccent,
        tertiary = brand.accent,
        background = brand.paper,
        onBackground = brand.ink,
        surface = brand.paper,
        onSurface = brand.ink,
        onSurfaceVariant = brand.secondary,
        surfaceVariant = brand.paperDeep,
        surfaceContainerLowest = brand.surface,
        surfaceContainerLow = brand.surface,
        surfaceContainer = brand.surface,
        surfaceContainerHigh = brand.surface,
        surfaceContainerHighest = brand.paperDeep,
        surfaceTint = Color.Transparent,
        outline = brand.secondary,
        outlineVariant = brand.ink.copy(alpha = 0.12f),
        secondaryContainer = brand.accent.copy(alpha = 0.18f),
        onSecondaryContainer = brand.ink,
        primaryContainer = brand.accent.copy(alpha = 0.18f),
        onPrimaryContainer = brand.ink,
    )
    CompositionLocalProvider(LocalBrand provides brand) {
        MaterialTheme(colorScheme = scheme, content = content)
    }
}
