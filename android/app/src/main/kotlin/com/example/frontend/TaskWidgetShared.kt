package com.example.frontend

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

object TaskWidgetShared {
    const val PREFS_NAME = "HomeWidgetPreferences"
    const val KEY_TASKS_JSON = "widget_tasks_json"
    const val KEY_SELECTED_DATE = "widget_selected_date"
    const val KEY_FOCUSED_MONTH = "widget_focused_month"
    const val KEY_WINDOW_START = "widget_window_start"
    const val KEY_COUNTERS_JSON = "widget_counters_json"
    const val KEY_LAST_UPDATED_TEXT = "widget_last_updated_text"

    fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun todayString(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Calendar.getInstance().time)

    fun monthString(calendar: Calendar): String = SimpleDateFormat("yyyy-MM", Locale.US).format(calendar.time)

    fun parseDate(dateString: String?): Calendar? {
        if (dateString.isNullOrBlank()) return null
        return try {
            val date = SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(dateString) ?: return null
            Calendar.getInstance().apply {
                time = date
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
        } catch (_: Exception) {
            null
        }
    }

    fun parseMonth(monthString: String?): Calendar {
        val fallback = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (monthString.isNullOrBlank()) return fallback
        return try {
            val date = SimpleDateFormat("yyyy-MM", Locale.US).parse(monthString) ?: return fallback
            Calendar.getInstance().apply {
                time = date
                set(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
        } catch (_: Exception) {
            fallback
        }
    }

    fun dateString(calendar: Calendar): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

    fun windowStartForDate(date: Calendar): Calendar {
        val cal = date.clone() as Calendar
        val dow = cal.get(Calendar.DAY_OF_WEEK)
        cal.add(Calendar.DAY_OF_MONTH, -(dow - Calendar.SUNDAY))
        cal.add(Calendar.WEEK_OF_YEAR, -1)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal
    }

    fun parseTasks(tasksJson: String?): List<JSONObject> {
        if (tasksJson.isNullOrBlank()) return emptyList()
        return try {
            val arr = JSONArray(tasksJson)
            List(arr.length()) { index -> arr.optJSONObject(index) ?: JSONObject() }
        } catch (_: Exception) {
            emptyList()
        }
    }
}

