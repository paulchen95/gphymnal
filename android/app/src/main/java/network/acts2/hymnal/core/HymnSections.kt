package network.acts2.hymnal.core

/** A letter of the indexed list and its hymns. */
data class HymnSection(val letter: String, val hymns: List<Hymn>)

object HymnSections {
    /** Hymns whose title or lyrics contain [query], ignoring case, in their original order. `fixtures/search.json`. */
    fun search(hymns: List<Hymn>, query: String): List<Hymn> {
        if (query.isEmpty()) return hymns
        return hymns.filter { it.name.contains(query, ignoreCase = true) || it.text.contains(query, ignoreCase = true) }
    }

    /** Hymns grouped by index letter, A–Z then "#", each sorted by its Latin form. `fixtures/sections.json`. */
    fun sections(hymns: List<Hymn>): List<HymnSection> =
        hymns.groupBy { it.indexLetter }
            .toSortedMap(compareBy<String> { it == "#" }.thenBy { it })
            .map { (letter, group) -> HymnSection(letter, group.sortedBy { it.sortKey }) }

    /** Everything the list shows: Christmas hymns dropped if hidden, then search, then sections. */
    fun visible(hymns: List<Hymn>, query: String, showChristmas: Boolean): List<HymnSection> =
        sections(search(hymns.filter { showChristmas || !it.isChristmas }, query))
}
