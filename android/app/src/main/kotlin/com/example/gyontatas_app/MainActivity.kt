package com.example.gyontatas_app

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.Context

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hu.miserend.gyontatas_app/background"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Alkalmazás kilépésének megakadályozása
        val isTaskRoot = isTaskRoot()
        if (!isTaskRoot) {
            val intent = intent
            if (intent.hasCategory(Intent.CATEGORY_LAUNCHER) && Intent.ACTION_MAIN == intent.action) {
                finish()
                return
            }
        }
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Metódus csatorna létrehozása a Flutter és natív kód közötti kommunikációhoz
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "isAppInForeground" -> {
                    result.success(isAppForeground())
                }
                "preventAppExit" -> {
                    val prevent = call.argument<Boolean>("prevent") ?: false
                    result.success(prevent)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // Ellenőrzi, hogy az alkalmazás előtérben van-e
    private fun isAppForeground(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = packageName
        
        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND && appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }
}
