package network.acts2.hymnal

import android.content.Context
import com.mixpanel.android.mpmetrics.MixpanelAPI
import network.acts2.hymnal.analytics.Analytics
import network.acts2.hymnal.analytics.AnalyticsEvent
import network.acts2.hymnal.analytics.AnalyticsSink
import org.json.JSONObject

/**
 * Android's analytics: Mixpanel's SDK, which queues events on the device and sends them when
 * it can, so the app stays fully usable offline. Its automatic events (first open, sessions,
 * app updates) come on top of ours. Anonymous: the SDK's own device ID, no sign-in.
 */
class MixpanelSink(context: Context, version: String) : AnalyticsSink {
    private val mixpanel = MixpanelAPI.getInstance(context, Analytics.MIXPANEL_TOKEN, /* trackAutomaticEvents = */ true).apply {
        registerSuperProperties(JSONObject(mapOf("platform" to "android", "app_version" to version)))
    }

    override fun send(event: AnalyticsEvent) {
        mixpanel.track(event.name, JSONObject(event.properties))
    }
}
