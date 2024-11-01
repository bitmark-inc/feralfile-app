package com.bitmark.autonomy_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.util.Calendar

/**
 * Implementation of App Widget functionality.
 */
class FeralfileDaily : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // Intent to open the app
            val openAppIntent = Intent(context, MainActivity::class.java)
            openAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )


            // Set up the layout for the widget
            val views = RemoteViews(context.packageName, R.layout.feralfile_daily)

            // Set onClick to update the widget and open the app
            views.setOnClickPendingIntent(R.id.daily_widget, openAppPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)

//            getDailyInfo(context = context) { dailyInfo ->
//                updateAppWidget(context, appWidgetManager, appWidgetId, dailyInfo)
//            }
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        // print log
        println("FeralfileDaily onEnabled")
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
        // print log
        println("FeralfileDaily onDisabled")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Handle the widget update and open app action


        // Check if the intent is to open the app
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, FeralfileDaily::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
            // Open the app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            context.startActivity(openAppIntent)


        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    dailyInfo: DailyInfo // dailyInfo is guaranteed to be non-null
) {
    val layoutId = R.layout.feralfile_daily
    val views = RemoteViews(context.packageName, layoutId)

    // Set text fields with DailyInfo
    views.setTextViewText(R.id.appwidget_title, dailyInfo.title)
    views.setTextViewText(R.id.appwidget_artist, dailyInfo.artistName)
//    views.setTextViewText(R.id.appwidget_medium, dailyInfo.medium)

    // Load the image from Base64
    val base64ImageData = dailyInfo.base64ImageData
    if (base64ImageData.isNotEmpty()) {
        try {
            // Decode Base64 string to a byte array
            val imageBytes = Base64.decode(base64ImageData, Base64.DEFAULT)
            // Convert byte array to Bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

            // Set the image to the widget
            views.setImageViewBitmap(R.id.appwidget_image, bitmap)
        } catch (e: Exception) {
            // Handle error in decoding, set a placeholder image
            views.setImageViewResource(R.id.appwidget_image, R.drawable.failed_daily_image)
        }
    } else {
        // If no Base64 data, set a placeholder image
        views.setImageViewResource(R.id.appwidget_image, R.drawable.no_thumbnail)
    }

    // Update the widget with the new views
    appWidgetManager.updateAppWidget(appWidgetId, views)
}

data class DailyInfo(
    val base64ImageData: String,  // Changed from thumbnailUrl to base64ImageData
    val title: String,
    val artistName: String,
    val medium: String
)


fun getDailyInfo(context: Context, callback: (DailyInfo) -> Unit) {
    CoroutineScope(Dispatchers.IO).launch {
        val localDailyInfo =
            getStoredDailyInfo(context = context) // Method to get previously stored data
        withContext(Dispatchers.Main) {
            callback(localDailyInfo)
        }
    }
}

private fun getStoredDailyInfo(context: Context): DailyInfo {
    val widgetData = HomeWidgetPlugin.getData(context)

    // Format the current date to match the key in the stored dat
    // now - 6h
    // Initialize calendar and set it to midnight 6 hours ago
    val calendar = Calendar.getInstance().apply {
        add(Calendar.HOUR_OF_DAY, -6)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    val timestamp = calendar.timeInMillis


    val currentDateKey = timestamp.toString()

    // Retrieve JSON string for the current date
    val jsonString = widgetData.getString(currentDateKey, null)

    if (jsonString != null) {
        try {
            // Parse JSON string
            val jsonObject = JSONObject(jsonString)
            val base64ImageData = jsonObject.optString("base64ImageData", "default_base64ImageData")
            val title = jsonObject.optString("title", "default_title")
            val artistName = jsonObject.optString("artistName", "default_artist_name")
            val medium = jsonObject.optString("medium", "default_medium")

            // Return DailyInfo object with the parsed data
            return DailyInfo(
                base64ImageData = base64ImageData,
                title = title,
                artistName = artistName,
                medium = medium
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Return default DailyInfo if data for current date is not found or parsing fails
    return DailyInfo(
        base64ImageData = "", // it's will be handle in case when base64ImageData is empty
        title = "Daily Artwork",
        artistName = "Daily is not available",
        medium = ""
    )
}


