package network.acts2.hymnal.desktop

import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.analytics.AnalyticsSink
import java.io.File
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.prefs.Preferences

/**
 * The desktop's analytics. Mixpanel has no SDK for a desktop JVM app, so this sends the same
 * events as Android and Apple straight to its HTTP API (`/track`), with what the SDKs would
 * add: an anonymous device ID, a timestamp and a de-duplication ID.
 *
 * The app works offline, and must behind China's firewall, so events wait in a file
 * ([queueFile]) and go in batches from a background thread, every minute and when the app
 * quits. Nothing here ever blocks the window or throws into the app.
 */
class MixpanelHttpSink(
    prefs: Preferences,
    /** The version Android and Apple share, e.g. "5.4.0". */
    private val appVersion: String,
    private val queueFile: File = defaultQueueFile(),
) : AnalyticsSink {
    private val deviceId: String = prefs.get(DEVICE_ID_KEY, null) ?: UUID.randomUUID().toString().also {
        prefs.put(DEVICE_ID_KEY, it)
        prefs.flush()
    }
    private val platform = if (System.getProperty("os.name").startsWith("Windows")) "windows" else "desktop"
    private val worker = Executors.newSingleThreadScheduledExecutor { Thread(it, "analytics").apply { isDaemon = true } }
    private val http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build()

    init {
        worker.scheduleWithFixedDelay(::flush, 5, 60, TimeUnit.SECONDS)
    }

    override fun send(event: AnalyticsEvent) {
        val properties = event.properties + mapOf(
            "token" to Analytics.MIXPANEL_TOKEN,
            "distinct_id" to deviceId,
            "\$device_id" to deviceId,
            "time" to System.currentTimeMillis(),
            "\$insert_id" to UUID.randomUUID().toString().replace("-", ""),
            "platform" to platform,
            "app_version" to appVersion,
            "\$os" to System.getProperty("os.name"),
            "\$os_version" to System.getProperty("os.version"),
            "mp_lib" to "a2n-hymnal-desktop",
        )
        val line = Json.encode(mapOf("event" to event.name, "properties" to properties))
        worker.execute { queue(line) }
    }

    /** Sends what's waiting, then stops; for when the app quits. Gives up after a few seconds. */
    fun shutdown() {
        worker.execute(::flush)
        worker.shutdown()
        worker.awaitTermination(5, TimeUnit.SECONDS)
    }

    // Everything below runs on the worker thread, one task at a time.

    private fun queue(line: String) = guarded {
        queueFile.parentFile?.mkdirs()
        // Keep the newest events if the device stays offline for a long time.
        val lines = (readQueue() + line).takeLast(MAX_QUEUED)
        queueFile.writeText(lines.joinToString("\n", postfix = "\n"))
    }

    private fun flush() = guarded {
        var lines = readQueue()
        while (lines.isNotEmpty()) {
            val batch = lines.take(BATCH_SIZE)
            val request = HttpRequest.newBuilder(URI("https://api.mixpanel.com/track?strict=1"))
                .timeout(Duration.ofSeconds(20))
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(batch.joinToString(",", "[", "]")))
                .build()
            val status = http.send(request, HttpResponse.BodyHandlers.ofString()).statusCode()
            // 400 means Mixpanel rejected the batch (e.g. events over five days old): sending it
            // again won't help. Anything else that isn't a success: try again next time.
            if (status != 200 && status != 400) return@guarded
            lines = lines.drop(batch.size)
            queueFile.writeText(if (lines.isEmpty()) "" else lines.joinToString("\n", postfix = "\n"))
        }
    }

    private fun readQueue(): List<String> =
        if (queueFile.exists()) queueFile.readLines().filter { it.isNotBlank() } else emptyList()

    /** Offline is normal, and analytics must never break the app. */
    private fun guarded(block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            // Kept quiet: no network is the usual reason.
        }
    }

    companion object {
        private const val DEVICE_ID_KEY = "analyticsDeviceId"
        private const val BATCH_SIZE = 50
        private const val MAX_QUEUED = 2000

        /** %LOCALAPPDATA%\A2N Hymnal on Windows; ~/.a2n-hymnal elsewhere (development). */
        fun defaultQueueFile(): File {
            val base = System.getenv("LOCALAPPDATA")?.let { File(it, "A2N Hymnal") }
                ?: File(System.getProperty("user.home"), ".a2n-hymnal")
            return File(base, "analytics-queue.jsonl")
        }
    }
}

/** Just enough JSON for analytics events: maps, strings, numbers and booleans. */
internal object Json {
    fun encode(value: Any?): String = when (value) {
        null -> "null"
        is String -> string(value)
        is Boolean, is Int, is Long -> value.toString()
        is Number -> value.toDouble().let { if (it.isFinite()) it.toString() else "null" }
        is Map<*, *> -> value.entries.joinToString(",", "{", "}") { (k, v) -> string(k.toString()) + ":" + encode(v) }
        is Iterable<*> -> value.joinToString(",", "[", "]") { encode(it) }
        else -> string(value.toString())
    }

    private fun string(s: String): String = buildString {
        append('"')
        for (c in s) {
            when (c) {
                '"' -> append("\\\"")
                '\\' -> append("\\\\")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
            }
        }
        append('"')
    }
}
