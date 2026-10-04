package network.acts2.hymnal

import com.ibm.icu.text.Transliterator
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.HymnLink
import network.acts2.hymnal.core.HymnParser
import network.acts2.hymnal.core.HymnSections
import network.acts2.hymnal.core.LyricsTextSize
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Runs the JSON examples in `content/fixtures/`, the Apple app's `SharedFixtureTests` also
 * runs, so the two apps can't drift on these rules.
 */
class SharedFixtureTest {
    private fun fixture(name: String): JSONObject =
        JSONObject(javaClass.classLoader!!.getResource(name)!!.readText())

    private fun JSONArray.strings() = List(length()) { getString(it) }
    private fun JSONArray.objects() = List(length()) { getJSONObject(it) }

    @Test
    fun parsing() {
        for (case in fixture("parsing.json").getJSONArray("cases").objects()) {
            val hymn = HymnParser.parse(case.getString("file"), "Fixture")
            val expect = case.getJSONObject("expect")
            val actual = mapOf(
                "name" to hymn.name, "author" to hymn.author, "translator" to hymn.translator,
                "composer" to hymn.composer, "arranger" to hymn.arranger, "tune" to hymn.tune,
                "collection" to hymn.collection, "text" to hymn.text,
            )
            for (key in expect.keys()) {
                assertEquals("${case.getString("name")}: $key", expect.getString(key), actual[key])
            }
        }
    }

    @Test
    fun sections() {
        for (case in fixture("sections.json").getJSONArray("cases").objects()) {
            val hymns = case.getJSONArray("names").strings().map {
                Hymn(name = it, filename = it, sortKey = TestLatinizer.latinize(it))
            }
            val actual = HymnSections.sections(hymns).map { it.letter to it.hymns.map(Hymn::name) }
            val expected = case.getJSONArray("expect").objects().map {
                it.getString("letter") to it.getJSONArray("names").strings()
            }
            assertEquals(case.getString("name"), expected, actual)
        }
    }

    @Test
    fun favorites() {
        for (case in fixture("favorites.json").getJSONArray("cases").objects()) {
            val christmas = case.optJSONArray("christmas")?.strings().orEmpty().toSet()
            val hymns = case.getJSONArray("names").strings().map {
                Hymn(name = it, filename = it, sortKey = TestLatinizer.latinize(it),
                    collection = if (it in christmas) Hymn.CHRISTMAS else Hymn.DEFAULT_COLLECTION)
            }
            val actual = HymnSections.visible(
                hymns, case.getString("query"), case.getBoolean("show_christmas"),
                case.getJSONArray("favorites").strings().toSet(),
            ).map { it.letter to it.hymns.map(Hymn::name) }
            val expected = case.getJSONArray("expect").objects().map {
                it.getString("letter") to it.getJSONArray("names").strings()
            }
            assertEquals(case.getString("name"), expected, actual)
        }
    }

    @Test
    fun search() {
        val json = fixture("search.json")
        val hymns = json.getJSONArray("hymns").objects().map {
            Hymn(name = it.getString("name"), filename = it.getString("name"), text = it.getString("text"))
        }
        for (case in json.getJSONArray("cases").objects()) {
            val query = case.getString("query")
            assertEquals(query, case.getJSONArray("expect").strings(), HymnSections.search(hymns, query).map(Hymn::name))
        }
    }

    @Test
    fun links() {
        val json = fixture("links.json")
        for (case in json.getJSONArray("slugs").objects()) {
            assertEquals(case.getString("slug"), HymnLink.slug(case.getString("filename")))
        }
        for (case in json.getJSONArray("urls").objects()) {
            val url = case.getString("url")
            val target = HymnLink.parse(url)
            if (case.isNull("slug")) {
                assertNull(url, target)
            } else {
                assertEquals(url, HymnLink.Target(case.getString("slug"), case.getBoolean("play")), target)
            }
        }
    }

    @Test
    fun textSize() {
        val json = fixture("text-size.json")
        val multipliers = json.getJSONArray("multipliers").let { a -> List(a.length()) { a.getDouble(it).toFloat() } }
        assertEquals(multipliers, LyricsTextSize.multipliers)
        assertEquals(json.getInt("default_step"), LyricsTextSize.DEFAULT_STEP)
        val percents = json.getJSONArray("percents").let { a -> List(a.length()) { a.getInt(it) } }
        assertEquals(percents, multipliers.indices.map(LyricsTextSize::percent))
        val range = json.getJSONArray("point_range")
        assertEquals(range.getDouble(0).toFloat(), LyricsTextSize.pointRange.start)
        assertEquals(range.getDouble(1).toFloat(), LyricsTextSize.pointRange.endInclusive)
        // Clamped at both ends, even with a very small or very large system font.
        assertEquals(14f, LyricsTextSize.pointSize(0, fontScale = 0.5f))
        assertEquals(48f, LyricsTextSize.pointSize(multipliers.lastIndex, fontScale = 2f))
    }
}

/** ICU4J's copy of the transform the app runs on Android's built-in ICU. */
object TestLatinizer : HymnParser.Latinizer {
    private val transliterator = Transliterator.getInstance(HymnParser.LATIN_TRANSFORM)
    override fun latinize(text: String): String = transliterator.transliterate(text)
}
