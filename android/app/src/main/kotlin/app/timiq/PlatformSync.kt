package app.timiq

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min

object PlatformSync {
    private const val TAG = "TimIQ.Platform"
    private const val PREFS = "timiq_platform"
    private const val KEY_ACTIVE = "active"
    private const val KEY_FAVORITES = "favorites"
    private const val NOTIFICATION_CHANNEL = "timiq_tracking"
    private const val NOTIFICATION_ID = 8100

    fun saveFlutterPayload(context: Context, payload: Map<String, Any?>) {
        val favorites = JSONArray()
        (payload["favorites"] as? List<*>)?.forEach { item ->
            (item as? Map<*, *>)?.let { favorites.put(mapToJson(it)) }
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_FAVORITES, favorites.toString())
            .commit()
        refreshActiveFromDatabase(context)
    }

    fun setActive(context: Context, active: JSONObject?) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ACTIVE, active?.toString())
            .apply()
    }

    fun active(context: Context): JSONObject? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ACTIVE, null)
            ?: return null
        return try {
            JSONObject(raw)
        } catch (error: Exception) {
            Log.e(TAG, "Invalid cached active timer payload", error)
            null
        }
    }

    fun favorites(context: Context): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_FAVORITES, "[]")
            ?: "[]"
        return try {
            JSONArray(raw)
        } catch (error: Exception) {
            Log.e(TAG, "Invalid cached favorites payload", error)
            JSONArray()
        }
    }

    fun refreshActiveFromDatabase(context: Context): Boolean {
        val databaseFile = context.getDatabasePath("timiq.db")
        if (!databaseFile.exists()) {
            setActive(context, null)
            return true
        }
        var active: JSONObject? = null
        val success = withDatabase(context, writable = false) { db ->
            db.rawQuery(
                """
                SELECT e.id, a.id, a.name, c.name,
                       COALESCE(a.custom_color_value, c.color_value), e.start_time
                FROM time_entries e
                INNER JOIN activities a ON a.id = e.activity_id
                INNER JOIN categories c ON c.id = a.category_id
                WHERE e.end_time IS NULL
                LIMIT 1
                """.trimIndent(),
                null,
            ).use { cursor ->
                if (cursor.moveToFirst()) {
                    active = JSONObject()
                        .put("entryId", cursor.getString(0))
                        .put("activityId", cursor.getString(1))
                        .put("activityName", cursor.getString(2))
                        .put("categoryName", cursor.getString(3))
                        .put("color", cursor.getInt(4))
                        .put("startTime", cursor.getLong(5))
                }
            }
        }
        if (success) setActive(context, active)
        return success
    }

    fun updateFavoriteTotals(context: Context): Boolean {
        val databaseFile = context.getDatabasePath("timiq.db")
        if (!databaseFile.exists()) return false
        val values = favorites(context)
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val dayStart = calendar.timeInMillis
        val dayEnd = (calendar.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, 1)
        }.timeInMillis
        val now = System.currentTimeMillis()
        val success = withDatabase(context, writable = false) { db ->
            for (index in 0 until values.length()) {
                val item = values.optJSONObject(index) ?: continue
                val activityId = item.optString("activityId")
                var total = 0L
                db.query(
                    "time_entries",
                    arrayOf("start_time", "end_time"),
                    "activity_id = ? AND start_time < ? " +
                        "AND (end_time IS NULL OR end_time > ?)",
                    arrayOf(activityId, dayEnd.toString(), dayStart.toString()),
                    null,
                    null,
                    null,
                ).use { cursor ->
                    while (cursor.moveToNext()) {
                        val start = cursor.getLong(0)
                        val end = if (cursor.isNull(1)) now else cursor.getLong(1)
                        total += max(
                            0L,
                            min(end, dayEnd) - max(start, dayStart),
                        )
                    }
                }
                item.put("trackedToday", total)
            }
        }
        if (success) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_FAVORITES, values.toString())
                .commit()
        }
        return success
    }

    fun refreshSurfaces(context: Context) {
        updateWidgets(context)
        updateNotification(context)
    }

    fun updateWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        listOf(
            TimiqSmallWidget::class.java,
            TimiqMediumWidget::class.java,
            TimiqLargeWidget::class.java,
        ).forEach { widgetClass ->
            val component = ComponentName(context, widgetClass)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { id ->
                manager.updateAppWidget(
                    id,
                    buildWidget(
                        context,
                        when (widgetClass) {
                            TimiqSmallWidget::class.java -> WidgetSize.SMALL
                            TimiqMediumWidget::class.java -> WidgetSize.MEDIUM
                            else -> WidgetSize.LARGE
                        },
                    ),
                )
            }
        }
    }

    fun buildWidget(context: Context, size: WidgetSize): RemoteViews {
        val layout = when (size) {
            WidgetSize.SMALL -> R.layout.widget_small
            WidgetSize.MEDIUM -> R.layout.widget_medium
            WidgetSize.LARGE -> R.layout.widget_large
        }
        val views = RemoteViews(context.packageName, layout)
        val active = active(context)
        val openIntent = PendingIntent.getActivity(
            context,
            1,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, openIntent)
        bindActive(views, active)
        if (size != WidgetSize.SMALL) {
            bindFavorites(
                context,
                views,
                favorites(context),
                if (size == WidgetSize.MEDIUM) 3 else 6,
            )
        }
        return views
    }

    private fun bindActive(views: RemoteViews, active: JSONObject?) {
        if (active == null) {
            views.setTextViewText(R.id.widget_activity, "Nic právě neběží")
            views.setTextViewText(R.id.widget_category, "Klepnutím otevřete TimIQ")
            views.setViewVisibility(R.id.widget_chronometer, android.view.View.GONE)
            return
        }
        views.setTextViewText(
            R.id.widget_activity,
            active.optString("activityName", "Aktivita"),
        )
        views.setTextViewText(
            R.id.widget_category,
            active.optString("categoryName", "TIMIQ").uppercase(),
        )
        views.setTextColor(
            R.id.widget_category,
            active.optInt("color", Color.rgb(124, 108, 255)),
        )
        val elapsed = max(0L, System.currentTimeMillis() - active.optLong("startTime"))
        views.setChronometer(
            R.id.widget_chronometer,
            android.os.SystemClock.elapsedRealtime() - elapsed,
            null,
            true,
        )
        views.setViewVisibility(
            R.id.widget_chronometer,
            android.view.View.VISIBLE,
        )
    }

    private fun bindFavorites(
        context: Context,
        views: RemoteViews,
        favorites: JSONArray,
        maximum: Int,
    ) {
        val buttonIds = intArrayOf(
            R.id.favorite_1,
            R.id.favorite_2,
            R.id.favorite_3,
            R.id.favorite_4,
            R.id.favorite_5,
            R.id.favorite_6,
        )
        for (index in buttonIds.indices) {
            val buttonId = buttonIds[index]
            if (index >= maximum || index >= favorites.length()) {
                views.setViewVisibility(buttonId, android.view.View.GONE)
                continue
            }
            val item = favorites.optJSONObject(index) ?: continue
            val name = item.optString("activityName", "Aktivita")
            val tracked = formatDuration(item.optLong("trackedToday"))
            views.setTextViewText(
                buttonId,
                if (maximum > 3) "$name  ·  $tracked" else name,
            )
            views.setViewVisibility(buttonId, android.view.View.VISIBLE)
            views.setOnClickPendingIntent(
                buttonId,
                TimerActionReceiver.startIntent(
                    context,
                    item.optString("activityId"),
                    index,
                ),
            )
        }
    }

    private fun updateNotification(context: Context) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val active = active(context)
        if (active == null) {
            manager.cancel(NOTIFICATION_ID)
            return
        }
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "Aktivní měření TimIQ",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Zobrazuje právě měřenou aktivitu."
                    setShowBadge(false)
                },
            )
        }
        val openIntent = PendingIntent.getActivity(
            context,
            2,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = TimerActionReceiver.stopIntent(context)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, NOTIFICATION_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val stopAction = Notification.Action.Builder(
            R.drawable.ic_stat_timiq,
            "Zastavit",
            stopIntent,
        ).build()
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_timiq)
            .setContentTitle(active.optString("activityName", "TimIQ"))
            .setContentText(
                "${active.optString("categoryName", "Aktivita")} · měření běží",
            )
            .setColor(active.optInt("color", Color.rgb(124, 108, 255)))
            .setWhen(active.optLong("startTime"))
            .setUsesChronometer(true)
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(openIntent)
            .addAction(stopAction)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun mapToJson(map: Map<*, *>): JSONObject {
        val result = JSONObject()
        map.forEach { (key, value) ->
            if (key != null) result.put(key.toString(), value)
        }
        return result
    }

    private fun formatDuration(milliseconds: Long): String {
        val minutes = milliseconds / 60_000L
        val hours = minutes / 60L
        val rest = minutes % 60L
        return if (hours > 0) "$hours h ${rest} min" else "$minutes min"
    }

    internal fun withDatabase(
        context: Context,
        writable: Boolean,
        action: (SQLiteDatabase) -> Unit,
    ): Boolean {
        val file = context.getDatabasePath("timiq.db")
        if (!file.exists()) {
            Log.w(TAG, "TimIQ database does not exist yet")
            return false
        }
        repeat(3) { attempt ->
            try {
                val flags = if (writable) {
                    SQLiteDatabase.OPEN_READWRITE
                } else {
                    SQLiteDatabase.OPEN_READONLY
                }
                SQLiteDatabase.openDatabase(file.absolutePath, null, flags)
                    .use(action)
                return true
            } catch (error: SQLiteException) {
                if (attempt == 2) {
                    Log.e(TAG, "SQLite operation failed after retries", error)
                    return false
                }
                Log.w(TAG, "SQLite temporarily unavailable; retrying", error)
                Thread.sleep(40L * (attempt + 1))
            } catch (error: Exception) {
                Log.e(TAG, "Native TimIQ database operation failed", error)
                return false
            }
        }
        return false
    }
}

enum class WidgetSize {
    SMALL,
    MEDIUM,
    LARGE,
}
