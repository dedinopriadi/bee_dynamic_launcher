package dev.bee.bee_dynamic_launcher

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class BeeDynamicLauncherPluginTest {
    @Test
    fun onMethodCall_unknown_returnsNotImplemented() {
        val plugin = BeeDynamicLauncherPlugin()
        val call = MethodCall("unknown", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)
        Mockito.verify(mockResult).notImplemented()
    }
}
