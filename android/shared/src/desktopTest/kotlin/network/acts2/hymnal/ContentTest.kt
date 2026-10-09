package network.acts2.hymnal

import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnParser
import network.acts2.hymnal.core.HymnSections
import network.acts2.hymnal.core.Locales
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * The real hymn files parse on Android the way they do on Apple. `tools/validate-content`
 * checks the files themselves in more depth.
 */
class ContentTest {
    private val content = File(System.getProperty("contentDir")!!)

    private fun hymns(locale: String): List<Hymn> =
        content.resolve("hymns/$locale").listFiles { f -> f.extension == "txt" }!!.map {
            HymnParser.parse(it.readText(), it.nameWithoutExtension, locale, TestLatinizer)
        }

    @Test
    fun everyLocaleHasHymnsWithATitleAndLyrics() {
        for (locale in Locales.all.keys) {
            val hymns = hymns(locale)
            assertTrue(locale, hymns.isNotEmpty())
            for (hymn in hymns) {
                assertTrue("${hymn.filename} ($locale) has no name", hymn.name.isNotBlank())
                assertTrue("${hymn.filename} ($locale) has no lyrics", hymn.text.isNotBlank())
                assertTrue("${hymn.filename} ($locale): ${hymn.collection}", hymn.collection in setOf("Hymn", "Christmas"))
            }
        }
    }

    /** Windows checks the files out with CRLF line endings; they must parse the same. */
    @Test
    fun windowsLineEndingsParseTheSame() {
        for (locale in Locales.all.keys) {
            for (file in content.resolve("hymns/$locale").listFiles { f -> f.extension == "txt" }!!) {
                val lf = file.readText().replace("\r\n", "\n")
                assertEquals(
                    "${file.name} ($locale)",
                    HymnParser.parse(lf, file.nameWithoutExtension, locale, TestLatinizer),
                    HymnParser.parse(lf.replace("\n", "\r\n"), file.nameWithoutExtension, locale, TestLatinizer),
                )
            }
        }
    }

    @Test
    fun translationsReuseEnglishFilenames() {
        val english = hymns("en-us").map(Hymn::filename).toSet()
        for (locale in Locales.all.keys - "en-us") {
            assertEquals(locale, emptySet<String>(), hymns(locale).map(Hymn::filename).toSet() - english)
        }
    }

    @Test
    fun everyRecordingBelongsToAHymn() {
        val english = hymns("en-us").map(Hymn::filename).toSet()
        val recordings = content.resolve("music").listFiles { f -> f.extension == "mp3" }!!.map { it.nameWithoutExtension }
        assertTrue(recordings.isNotEmpty())
        assertEquals(emptySet<String>(), recordings.toSet() - english)
    }

    @Test
    fun chineseTitlesFileUnderLetters() {
        for (locale in listOf("zh-cn", "zh-tw")) {
            val letters = HymnSections.sections(hymns(locale)).map { it.letter }
            assertTrue("$locale: $letters", letters.any { it != "#" })
        }
    }
}
