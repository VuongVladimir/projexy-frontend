package com.example.frontend

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri

class WidgetAutoRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val refreshIntent = Intent().apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            data = Uri.parse("projexywidget://refresh")
            component = ComponentName(
                context,
                "es.antonborri.home_widget.HomeWidgetBackgroundReceiver",
            )
        }
        context.sendBroadcast(refreshIntent)
    }
}
