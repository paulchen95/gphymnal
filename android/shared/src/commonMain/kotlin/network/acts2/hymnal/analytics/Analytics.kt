package network.acts2.hymnal.analytics

/**
 * One usage event: a name and its properties. Every app sends the same events to the same
 * Mixpanel project, so `content/fixtures/analytics.json` pins them; see `ANALYTICS.md`.
 */
data class AnalyticsEvent(val name: String, val properties: Map<String, Any> = emptyMap()) {
    companion object {
        fun appOpened() = AnalyticsEvent("App Opened")
        fun hymnViewed(hymn: String, locale: String) = AnalyticsEvent("Hymn Viewed", mapOf("hymn" to hymn, "locale" to locale))
        fun hymnPlayed(hymn: String, locale: String) = AnalyticsEvent("Hymn Played", mapOf("hymn" to hymn, "locale" to locale))
        fun hymnFinished(hymn: String, locale: String) = AnalyticsEvent("Hymn Finished", mapOf("hymn" to hymn, "locale" to locale))
        fun repeatToggled(enabled: Boolean) = AnalyticsEvent("Repeat Toggled", mapOf("enabled" to enabled))

        /** Never the search text itself: only how long it was and what it found. */
        fun hymnSearched(queryLength: Int, resultCount: Int) =
            AnalyticsEvent("Hymn Searched", mapOf("query_length" to queryLength, "result_count" to resultCount))

        fun favoriteAdded(hymn: String) = AnalyticsEvent("Favorite Added", mapOf("hymn" to hymn))
        fun favoriteRemoved(hymn: String) = AnalyticsEvent("Favorite Removed", mapOf("hymn" to hymn))

        /** [setting] is language, text_size (a percent), appearance, christmas_hymns or search_highlighting. */
        fun settingChanged(setting: String, value: Any) =
            AnalyticsEvent("Setting Changed", mapOf("setting" to setting, "value" to value))
    }
}

/** Where events go: Mixpanel's SDK on Android, its HTTP API on Windows (`MixpanelHttpSink`). */
fun interface AnalyticsSink {
    fun send(event: AnalyticsEvent)
}

/**
 * Anonymous usage analytics, in the A2N Hymnal Mixpanel project. Each app sets [sink] at
 * launch and tags every event with `platform` and `app_version`. Analytics must never break
 * the app, so a failing sink is ignored; with no sink (the tests), events are dropped.
 */
object Analytics {
    const val MIXPANEL_TOKEN = "030517a13efaff4880d81caee92d3d95"

    /** How long search text must sit still before it counts as a search. */
    const val SEARCH_DEBOUNCE_MS = 1500L

    var sink: AnalyticsSink? = null

    fun track(event: AnalyticsEvent) {
        try {
            sink?.send(event)
        } catch (e: Exception) {
            println("Analytics: couldn't send ${event.name}: $e")
        }
    }
}
