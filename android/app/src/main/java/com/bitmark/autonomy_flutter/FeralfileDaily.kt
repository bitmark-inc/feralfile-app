package com.bitmark.autonomy_flutter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.util.Date


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
            getDailyInfo(context = context) { dailyInfo ->
                updateAppWidget(context, appWidgetManager, appWidgetId, dailyInfo)
            }
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
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    dailyInfo: DailyInfo // dailyInfo is guaranteed to be non-null
) {
    val layoutId = R.layout.widget_2x2
    val views = RemoteViews(context.packageName, layoutId)

    // Set text fields with DailyInfo
    views.setTextViewText(R.id.appwidget_title, dailyInfo.title)
    views.setTextViewText(R.id.appwidget_artist, dailyInfo.artistName)
    views.setTextViewText(R.id.appwidget_medium, dailyInfo.medium)

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
    val now = Date()
    val date = Date(now.time - 6 * 60 * 60 * 1000)
    // current date to timestamp
    val currentDateKey = date.time.toString()

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


