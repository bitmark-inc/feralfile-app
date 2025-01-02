package com.bitmark.autonomy_flutter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.bitmark.autonomywallet.MainActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import timber.log.Timber
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

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
            Log.d("FeralfileDaily", "onUpdate $appWidgetId")
            startWidgetUpdateCycle(context, appWidgetManager, appWidgetId)
        }
    }

    private fun startWidgetUpdateCycle(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val dailyInfoList = getDailyInfoList(context)
            withContext(Dispatchers.Main) {
                updateWidgetWithCycle(context, appWidgetManager, appWidgetId, dailyInfoList)
            }
        }
    }

    private fun getCurrentIndex(dailyInfoList: List<DailyInfo>): Int {
        require(dailyInfoList.isNotEmpty()) { "Slide list must not be empty" }

        // Each slide lasts for a fixed duration (e.g., 5 minutes in this case).
        // At the start of the cycle, the index is 0.
        // As time progresses, the index increases every 5 minutes, cycling through the length of `slideInfos`.

        val now = System.currentTimeMillis()
        val startDate =
            getCurrentDate().atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val secondsSinceStart = (now - startDate) / 1000 // time in seconds

        // Calculate the current index based on the time elapsed and the length of `slideInfos`.
        val index = (secondsSinceStart / slideDurationInSeconds) % dailyInfoList.size

        return index.toInt()
    }

    private fun updateWidgetWithCycle(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        dailyInfoList: List<DailyInfo>
    ) {
        val handler = Handler(Looper.getMainLooper())
        var currentIndex = getCurrentIndex(dailyInfoList)

        val updateRunnable = object : Runnable {
            override fun run() {
                if (dailyInfoList.isNotEmpty()) {
                    val dailyInfo = dailyInfoList[currentIndex]
                    updateAppWidget(context, appWidgetManager, appWidgetId, dailyInfo)
                    currentIndex = getCurrentIndex(dailyInfoList)
                }
                handler.postDelayed(this, (slideDurationInSeconds + 3) * 1000)
            }
        }

        handler.post(updateRunnable)
    }

    override fun onEnabled(context: Context) {
        Timber.tag("FeralfileDaily").d("FeralfileDaily onEnabled")
    }

    override fun onDisabled(context: Context) {
        Timber.tag("FeralfileDaily").d("FeralfileDaily onDisabled")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        Timber.tag("FeralfileDaily").d("FeralfileDaily onReceive %s", intent.action)

        when (intent.action) {
            "com.bitmark.autonomy_flutter.OPEN_APP" -> {
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(openAppIntent)
            }

            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, FeralfileDaily::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        startWidgetUpdateCycle(context, appWidgetManager, appWidgetId)
    }
}

data class DailyInfo(
    val base64ImageData: String,
    val title: String,
    val artistName: String,
    val medium: String
)

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    dailyInfo: DailyInfo
) {
    val layoutId = R.layout.feralfile_daily
    val views = RemoteViews(context.packageName, layoutId)

    views.setTextViewText(R.id.appwidget_title, dailyInfo.title)
    views.setTextViewText(R.id.appwidget_artist, dailyInfo.artistName)

    setImageFromBase64(context, views, R.id.appwidget_image, dailyInfo.base64ImageData)
    if (dailyInfo.medium.isNotEmpty()) {
        setImageFromBase64(context, views, R.id.medium_image, dailyInfo.medium)
        views.setViewVisibility(R.id.medium_image, View.VISIBLE)
    } else {
        views.setViewVisibility(R.id.medium_image, View.GONE)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

fun setImageFromBase64(
    context: Context,
    views: RemoteViews,
    imageViewId: Int,
    base64Data: String
) {
    if (base64Data.isNotEmpty()) {
        try {
            val imageBytes = Base64.decode(base64Data, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            views.setImageViewBitmap(imageViewId, bitmap)
        } catch (e: Exception) {
            views.setImageViewResource(imageViewId, R.drawable.failed_daily_image)
        }
    } else {
        views.setImageViewResource(imageViewId, R.drawable.no_thumbnail)
    }
}

fun getDailyInfoList(context: Context): List<DailyInfo> {
    val widgetData = HomeWidgetPlugin.getData(context)
    val dailyInfoList = mutableListOf<DailyInfo>()

    val currentDateKey = getCurrentDateKey()
    val jsonString = widgetData.getString(currentDateKey, null)

    if (jsonString != null) {
        try {
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val string = jsonArray.getString(i)
                val jsonObject = org.json.JSONObject(string)
                val dailyInfo = DailyInfo(
                    base64ImageData = jsonObject.optString("base64ImageData", ""),
                    title = jsonObject.optString("title", "Default Title"),
                    artistName = jsonObject.optString("artistName", "Default Artist"),
                    medium = jsonObject.optString("base64MediumIcon", "")
                )
                dailyInfoList.add(dailyInfo)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    if (dailyInfoList.isEmpty()) {
        dailyInfoList.add(getDefaultDailyInfo())
    }

    return dailyInfoList
}

private fun getDefaultDailyInfo(): DailyInfo {
    return DailyInfo(
        base64ImageData = "",
        title = "Daily Artwork",
        artistName = "Daily is not available",
        medium = ""
    )
}

private fun getCurrentDate(): LocalDate {
    val current = LocalDate.now()
    return LocalDate.of(current.year, current.month, current.dayOfMonth)

}

private fun getCurrentDateKey(): String {
    val currentDate = getCurrentDate()
    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    return currentDate.format(formatter)
}
