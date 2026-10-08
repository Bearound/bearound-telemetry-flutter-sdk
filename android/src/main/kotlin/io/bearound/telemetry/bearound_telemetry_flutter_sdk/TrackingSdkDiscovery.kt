package io.bearound.telemetry.bearound_telemetry_flutter_sdk

import java.lang.reflect.Modifier

internal object TrackingSdkDiscovery {
    fun configuredInstanceOrNull(
        context: Any?,
        contextType: Class<*>,
        sdkClassProvider: () -> Class<*> = { Class.forName("io.bearound.sdk.BeAroundSDK") },
    ): Any? {
        return try {
            val sdkClass = sdkClassProvider()
            val (factory, receiver) = try {
                val method = sdkClass.getMethod("getInstance", contextType)
                if (!Modifier.isStatic(method.modifiers)) return null
                method to null
            } catch (_: NoSuchMethodException) {
                val field = sdkClass.getField("Companion")
                if (!Modifier.isStatic(field.modifiers)) return null
                val companion = field.get(null) ?: return null
                val method = companion.javaClass.getMethod("getInstance", contextType)
                if (Modifier.isStatic(method.modifiers)) return null
                method to companion
            }
            val instance = factory.invoke(receiver, context) ?: return null
            if (!sdkClass.isInstance(instance)) return null
            val getter = sdkClass.getMethod("getBusinessToken")
            if (Modifier.isStatic(getter.modifiers) || getter.returnType != String::class.java) return null
            val token = getter.invoke(instance) as? String
            if (token.isNullOrBlank()) null else instance
        } catch (_: Throwable) {
            null
        }
    }
}
