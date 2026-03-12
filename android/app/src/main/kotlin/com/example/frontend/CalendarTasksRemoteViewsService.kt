package com.example.frontend

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale

class CalendarTasksRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CalendarTasksFactory(applicationContext)
    }
}

private class CalendarTasksFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {
    private val tasks = mutableListOf<JSONObject>()
    private var selectedDate: String = TaskWidgetShared.todayString()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val prefs = TaskWidgetShared.prefs(context)
        selectedDate = prefs.getString(TaskWidgetShared.KEY_SELECTED_DATE, TaskWidgetShared.todayString())
            ?: TaskWidgetShared.todayString()

        val allTasks = TaskWidgetShared.parseTasks(prefs.getString(TaskWidgetShared.KEY_TASKS_JSON, "[]"))
        tasks.clear()
        tasks.addAll(
            allTasks.filter { task ->
                val due = task.optString("endDate", "")
                extractIsoDate(due) == selectedDate
            },
        )
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        val task = tasks[position]
        val taskId = task.optString("id", "")
        val title = task.optString("title", "Task")
        val projectTitle = task.optString("projectTitle", "")

        return RemoteViews(context.packageName, R.layout.widget_calendar_task_item).apply {
            setTextViewText(R.id.calendar_task_title, title)
            setTextViewText(
                R.id.calendar_task_subtitle,
                if (projectTitle.isBlank()) "Task detail" else projectTitle,
            )

            val fillInIntent = Intent().apply {
                data = Uri.parse("projexywidget://task-detail?taskId=$taskId")
            }
            setOnClickFillInIntent(R.id.calendar_task_item_root, fillInIntent)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    override fun onDestroy() {
        tasks.clear()
    }

    private fun extractIsoDate(isoValue: String): String {
        if (isoValue.length >= 10 && isoValue[4] == '-' && isoValue[7] == '-') {
            return isoValue.take(10)
        }
        return try {
            val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(isoValue)
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date!!)
        } catch (_: Exception) {
            try {
                val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).parse(isoValue)
                SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date!!)
            } catch (_: Exception) {
                ""
            }
        }
    }
}

