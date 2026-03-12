package com.example.frontend

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class TaskCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetRefreshScheduler.ensureScheduled(context)
        appWidgetIds.forEach { widgetId ->
            try {
                updateWidget(context, appWidgetManager, widgetId, widgetData)
            } catch (_: Exception) {
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val selectedDate = widgetData.getString(
            TaskWidgetShared.KEY_SELECTED_DATE,
            TaskWidgetShared.todayString(),
        ) ?: TaskWidgetShared.todayString()

        val selectedCal = TaskWidgetShared.parseDate(selectedDate) ?: Calendar.getInstance()
        val today = Calendar.getInstance()

        val defaultWindowStart = TaskWidgetShared.dateString(
            TaskWidgetShared.windowStartForDate(today),
        )
        val windowStartStr = widgetData.getString(
            TaskWidgetShared.KEY_WINDOW_START,
            defaultWindowStart,
        ) ?: defaultWindowStart
        val windowStart = TaskWidgetShared.parseDate(windowStartStr) ?: TaskWidgetShared.windowStartForDate(today)

        val tasksJson = widgetData.getString(TaskWidgetShared.KEY_TASKS_JSON, "[]") ?: "[]"
        val eventDates = parseEventDates(tasksJson)

        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val cells = buildWindowCells(windowStart)

        val views = RemoteViews(context.packageName, R.layout.widget_calendar_view)

        val firstDay = cells.first()
        val lastDay = cells.last()
        val monthTitle = if (firstDay.get(Calendar.MONTH) == lastDay.get(Calendar.MONTH)) {
            SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(firstDay.time)
        } else if (firstDay.get(Calendar.YEAR) == lastDay.get(Calendar.YEAR)) {
            SimpleDateFormat("MMM", Locale.getDefault()).format(firstDay.time) +
                " - " +
                SimpleDateFormat("MMM yyyy", Locale.getDefault()).format(lastDay.time)
        } else {
            SimpleDateFormat("MMM yyyy", Locale.getDefault()).format(firstDay.time) +
                " - " +
                SimpleDateFormat("MMM yyyy", Locale.getDefault()).format(lastDay.time)
        }
        views.setTextViewText(R.id.calendar_month_title, monthTitle)
        views.setTextViewText(
            R.id.calendar_selected_date_title,
            SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(selectedCal.time),
        )

        val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("projexywidget://refresh"),
        )
        views.setOnClickPendingIntent(R.id.calendar_refresh_button, refreshIntent)
        views.setInt(R.id.calendar_refresh_button, "setColorFilter", 0xFF274BFF.toInt())

        views.setOnClickPendingIntent(
            R.id.calendar_prev_month,
            monthActionIntent(context, ACTION_PREV_MONTH),
        )
        views.setOnClickPendingIntent(
            R.id.calendar_next_month,
            monthActionIntent(context, ACTION_NEXT_MONTH),
        )

        for (i in 0 until WEEK_COUNT * 7) {
            val day = cells[i]
            val cellDate = dateFormat.format(day.time)
            val isToday = isSameDay(day, today)
            val isSelected = cellDate == selectedDate
            val hasEvent = eventDates.contains(cellDate)

            views.setTextViewText(DAY_IDS[i], day.get(Calendar.DAY_OF_MONTH).toString())
            views.setInt(
                DAY_IDS[i],
                "setTextColor",
                when {
                    isSelected -> 0xFFFFFFFF.toInt()
                    hasEvent -> 0xFFEF736B.toInt()
                    else -> 0xFF202020.toInt()
                },
            )
            views.setInt(
                DAY_IDS[i],
                "setBackgroundResource",
                when {
                    isSelected -> R.drawable.widget_day_selected_bg
                    isToday -> R.drawable.widget_day_today_bg
                    else -> 0
                },
            )
            views.setOnClickPendingIntent(
                DAY_IDS[i],
                makeSelectDatePendingIntent(context, widgetId, i, cellDate),
            )
        }

        val tasksAdapterIntent = Intent(
            context,
            CalendarTasksRemoteViewsService::class.java,
        ).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            data = Uri.parse("projexywidget://calendar-tasks/$widgetId?date=$selectedDate")
        }
        @Suppress("DEPRECATION")
        views.setRemoteAdapter(R.id.calendar_tasks_list, tasksAdapterIntent)
        views.setEmptyView(R.id.calendar_tasks_list, R.id.calendar_tasks_empty)

        val templateIntent = Intent(context, MainActivity::class.java).apply {
            action = "es.antonborri.home_widget.action.LAUNCH"
        }
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
        val taskClickPendingIntent = PendingIntent.getActivity(
            context,
            widgetId,
            templateIntent,
            piFlags,
        )
        views.setPendingIntentTemplate(R.id.calendar_tasks_list, taskClickPendingIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.calendar_tasks_list)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_SELECT_DATE -> {
                val selectedDate = intent.getStringExtra(EXTRA_SELECTED_DATE) ?: return
                val prefs = TaskWidgetShared.prefs(context)
                prefs.edit()
                    .putString(TaskWidgetShared.KEY_SELECTED_DATE, selectedDate)
                    .apply()
                refreshAllInstances(context)
            }
            ACTION_PREV_MONTH, ACTION_NEXT_MONTH -> {
                val prefs = TaskWidgetShared.prefs(context)
                val defaultStart = TaskWidgetShared.dateString(
                    TaskWidgetShared.windowStartForDate(Calendar.getInstance()),
                )
                val windowStartStr = prefs.getString(
                    TaskWidgetShared.KEY_WINDOW_START,
                    defaultStart,
                ) ?: defaultStart
                val windowCal = TaskWidgetShared.parseDate(windowStartStr)
                    ?: TaskWidgetShared.windowStartForDate(Calendar.getInstance())
                windowCal.add(
                    Calendar.WEEK_OF_YEAR,
                    if (intent.action == ACTION_PREV_MONTH) -WEEK_COUNT else WEEK_COUNT,
                )
                prefs.edit()
                    .putString(
                        TaskWidgetShared.KEY_WINDOW_START,
                        TaskWidgetShared.dateString(windowCal),
                    )
                    .apply()
                refreshAllInstances(context)
            }
        }
    }

    private fun refreshAllInstances(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            android.content.ComponentName(context, TaskCalendarWidgetProvider::class.java),
        )
        onUpdate(context, manager, ids, TaskWidgetShared.prefs(context))
    }

    private fun monthActionIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, TaskCalendarWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun makeSelectDatePendingIntent(
        context: Context,
        widgetId: Int,
        index: Int,
        dateString: String,
    ): PendingIntent {
        val intent = Intent(context, TaskCalendarWidgetProvider::class.java).apply {
            action = ACTION_SELECT_DATE
            putExtra(EXTRA_SELECTED_DATE, dateString)
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId * 50 + index,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildWindowCells(windowStart: Calendar): List<Calendar> {
        val cells = mutableListOf<Calendar>()
        val start = windowStart.clone() as Calendar
        val dow = start.get(Calendar.DAY_OF_WEEK)
        start.add(Calendar.DAY_OF_MONTH, -(dow - Calendar.SUNDAY))
        repeat(WEEK_COUNT * 7) { i ->
            val day = start.clone() as Calendar
            day.add(Calendar.DAY_OF_MONTH, i)
            cells.add(day)
        }
        return cells
    }

    private fun parseEventDates(tasksJson: String): Set<String> {
        return try {
            val arr = JSONArray(tasksJson)
            val dates = mutableSetOf<String>()
            for (i in 0 until arr.length()) {
                val task = arr.optJSONObject(i) ?: continue
                val endDate = task.optString("endDate", "") ?: ""
                if (endDate.length >= 10) {
                    dates.add(endDate.take(10))
                }
            }
            dates
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun isSameDay(a: Calendar, b: Calendar): Boolean {
        return a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
            a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
    }

    companion object {
        const val ACTION_SELECT_DATE = "com.example.frontend.widget.ACTION_SELECT_DATE"
        const val ACTION_PREV_MONTH = "com.example.frontend.widget.ACTION_PREV_MONTH"
        const val ACTION_NEXT_MONTH = "com.example.frontend.widget.ACTION_NEXT_MONTH"
        const val EXTRA_SELECTED_DATE = "selectedDate"
        private const val WEEK_COUNT = 3

        private val DAY_IDS = intArrayOf(
            R.id.d0, R.id.d1, R.id.d2, R.id.d3, R.id.d4, R.id.d5, R.id.d6,
            R.id.d7, R.id.d8, R.id.d9, R.id.d10, R.id.d11, R.id.d12, R.id.d13,
            R.id.d14, R.id.d15, R.id.d16, R.id.d17, R.id.d18, R.id.d19, R.id.d20,
        )
    }
}
