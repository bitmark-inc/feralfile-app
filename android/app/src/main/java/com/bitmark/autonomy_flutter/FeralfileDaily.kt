package com.bitmark.autonomy_flutter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.widget.RemoteViews
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.AppWidgetTarget
import com.bumptech.glide.request.transition.Transition
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

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
            getDailyInfo(context = context, date = "2023-10-31") { dailyInfo ->
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
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.feralfile_daily)

    // Set text fields with DailyInfo
    views.setTextViewText(R.id.appwidget_title, dailyInfo.title)
    views.setTextViewText(R.id.appwidget_artist, dailyInfo.artistName)
    views.setTextViewText(R.id.appwidget_medium, dailyInfo.medium)

    // Load the thumbnail image
    val thumbnailUrl = dailyInfo.thumbnailUrl
    if (thumbnailUrl.isNotEmpty()) {
        // Use Glide to load the image into the widget
        Glide.with(context)
            .asBitmap()
            .load(thumbnailUrl)
            .into(object : AppWidgetTarget(context, R.id.appwidget_image, views, appWidgetId) {
                override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                    views.setImageViewBitmap(R.id.appwidget_image, resource)
                    // Update the widget with the new image
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }

                override fun onLoadFailed(errorDrawable: Drawable?) {
                    // Handle error, if needed, set a placeholder image
                    views.setImageViewResource(R.id.appwidget_image, R.drawable.failed_daily_image)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            })
    } else {
        // If no thumbnail URL, set a placeholder image
        views.setImageViewResource(R.id.appwidget_image, R.drawable.no_thumbnail)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

data class DailyInfo(
    val thumbnailUrl: String,
    val title: String,
    val artistName: String,
    val medium: String
)


fun getDailyInfo(context: Context, date: String, callback: (DailyInfo) -> Unit) {
    CoroutineScope(Dispatchers.IO).launch {
        try {

            // Create a DailyInfo from the API response, if available
            val dailyInfo = DailyInfo(
                thumbnailUrl = "https://via.placeholder.com/150",
                title = "Title",
                artistName = "Artist",
                medium = "Medium"
            )

            // If dailyInfo is null, retrieve already set data from local storage
            if (dailyInfo == null) {
                val localDailyInfo =
                    getStoredDailyInfo(context = context) // Method to get previously stored data
                withContext(Dispatchers.Main) {
                    callback(localDailyInfo)
                }
            } else {
                // If dailyInfo is valid, return it
                withContext(Dispatchers.Main) {
                    callback(dailyInfo)
                }
            }
        } catch (e: Exception) {
            // In case of an exception, fallback to retrieving stored data
            val localDailyInfo = getStoredDailyInfo(context = context)
            withContext(Dispatchers.Main) {
                callback(localDailyInfo)
            }
        }
    }
}

private fun getStoredDailyInfo(context: Context): DailyInfo {
    val widgetData = HomeWidgetPlugin.getData(context)
    val thumbnailUrl =
        widgetData.getString("thumbnailUrl", "default_thumbnail_url") ?: "default_thumbnail_url"
    val title = widgetData.getString("title", "default_title") ?: "default_title"
    val artistName =
        widgetData.getString("artistName", "default_artist_name") ?: "default_artist_name"
    val medium = widgetData.getString("medium", "default_medium") ?: "default_medium"
    // return
    return DailyInfo(
        thumbnailUrl = thumbnailUrl,
        title = title,
        artistName = artistName,
        medium = medium
    )
}


