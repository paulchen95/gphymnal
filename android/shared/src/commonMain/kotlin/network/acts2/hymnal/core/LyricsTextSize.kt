package network.acts2.hymnal.core

import kotlin.math.roundToInt

/**
 * The reader's lyrics size, set from the lyrics page or Settings (one stored value). Each
 * step multiplies a 17pt body size that already follows the system font size, and the result
 * is clamped so the two can't compound into something unusable. `fixtures/text-size.json`.
 */
object LyricsTextSize {
    const val STORAGE_KEY = "lyricsTextSizeStep"
    val multipliers = listOf(0.85f, 1.0f, 1.15f, 1.3f, 1.5f, 1.75f, 2.0f)
    const val DEFAULT_STEP = 1
    val pointRange = 14f..48f
    private const val BODY_SIZE = 17f

    fun clamped(step: Int): Int = step.coerceIn(0, multipliers.lastIndex)

    fun percent(step: Int): Int = (multipliers[clamped(step)] * 100).roundToInt()

    /** On-screen size for [step], given the system font scale. */
    fun pointSize(step: Int, fontScale: Float = 1f): Float =
        (BODY_SIZE * fontScale * multipliers[clamped(step)]).coerceIn(pointRange.start, pointRange.endInclusive)

    /** Line height of about 1.5 × the text size, the spacing WCAG recommends for readability. */
    const val LINE_HEIGHT = 1.5f
}
