package com.example.frontend

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class MyTasksWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetRefreshScheduler.ensureScheduled(context)
        val countersJson = widgetData.getString(TaskWidgetShared.KEY_COUNTERS_JSON, "{}") ?: "{}"
        val counters = try {
            JSONObject(countersJson)
        } catch (_: Exception) {
            JSONObject()
        }
        val lastUpdated = widgetData.getString(TaskWidgetShared.KEY_LAST_UPDATED_TEXT, "--:--") ?: "--:--"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_my_tasks).apply {
                setTextViewText(
                    R.id.counter_assigned_recently_value,
                    counters.optInt("assigned_recently", 0).toString(),
                )
                setTextViewText(
                    R.id.counter_due_today_value,
                    counters.optInt("due_today", 0).toString(),
                )
                setTextViewText(
                    R.id.counter_due_this_week_value,
                    counters.optInt("due_this_week", 0).toString(),
                )
                setTextViewText(
                    R.id.counter_updated_recently_value,
                    counters.optInt("updated_recently", 0).toString(),
                )
                setTextViewText(R.id.my_tasks_last_updated, "Updated: $lastUpdated")

                val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("projexywidget://refresh"),
                )
                setOnClickPendingIntent(R.id.my_tasks_refresh_button, refreshIntent)
                setInt(R.id.my_tasks_refresh_button, "setColorFilter", 0xFF274BFF.toInt())

                setOnClickPendingIntent(
                    R.id.counter_assigned_recently,
                    openFilterIntent(
                        context,
                        "assigned_recently",
                        "Assigned Recently",
                    ),
                )
                setOnClickPendingIntent(
                    R.id.counter_due_today,
                    openFilterIntent(context, "due_today", "Due Today"),
                )
                setOnClickPendingIntent(
                    R.id.counter_due_this_week,
                    openFilterIntent(context, "due_this_week", "Due This Week"),
                )
                setOnClickPendingIntent(
                    R.id.counter_updated_recently,
                    openFilterIntent(
                        context,
                        "updated_recently",
                        "Updated Recently",
                    ),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun openFilterIntent(
        context: Context,
        filter: String,
        title: String,
    ) = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("projexywidget://list-filter?filter=$filter&title=${Uri.encode(title)}"),
    )
}

