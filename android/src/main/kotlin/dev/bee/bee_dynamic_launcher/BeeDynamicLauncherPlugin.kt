package dev.bee.bee_dynamic_launcher

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class BeeDynamicLauncherPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var variantIds: List<String> = emptyList()
    private var primaryVariantId: String = ""

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<*, *>
                val ids = (args?.get("ids") as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                val primary = args?.get("primaryVariantId") as? String ?: ""
                if (ids.isEmpty() || primary.isEmpty()) {
                    result.error("INVALID_ARGUMENT", "ids and primaryVariantId required", null)
                    return
                }
                if (!ids.contains(primary)) {
                    result.error("INVALID_ARGUMENT", "primaryVariantId must be in ids", null)
                    return
                }
                variantIds = ids
                primaryVariantId = primary
                result.success(null)
            }
            "getAvailableVariants" -> result.success(variantIds)
            "getCurrentVariant" -> {
                if (variantIds.isEmpty()) {
                    result.success(null)
                    return
                }
                result.success(getCurrentVariant())
            }
            "applyVariant" -> {
                val id = call.arguments as? String
                if (variantIds.isEmpty()) {
                    result.error("NOT_INITIALIZED", "call initialize first", null)
                    return
                }
                if (id.isNullOrEmpty() || id !in variantIds) {
                    result.error("INVALID_ARGUMENT", "unknown variant id", null)
                    return
                }
                try {
                    applyVariant(id)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("APPLY_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun aliasSimpleClassName(id: String): String {
        if (id.isEmpty()) {
            return id
        }
        return id.split('_').joinToString("") { part ->
            if (part.isEmpty()) {
                return@joinToString ""
            }
            val first = part[0]
            val rest = part.substring(1)
            first.titlecase(Locale.getDefault()) + rest.lowercase(Locale.getDefault())
        }
    }

    private fun componentForVariant(id: String): ComponentName =
        ComponentName(context.packageName, "${context.packageName}.Launcher${aliasSimpleClassName(id)}")

    private fun getCurrentVariant(): String {
        val pm = context.packageManager
        for (id in variantIds) {
            val c = componentForVariant(id)
            if (pm.getComponentEnabledSetting(c) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return id
            }
        }
        return variantIds.firstOrNull() ?: primaryVariantId
    }

    private fun applyVariant(id: String) {
        val pm = context.packageManager
        for (vid in variantIds) {
            val c = componentForVariant(vid)
            val enabled = vid == id
            pm.setComponentEnabledSetting(
                c,
                if (enabled) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                },
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    companion object {
        private const val CHANNEL = "dev.bee.bee_dynamic_launcher/launcher"
    }
}
