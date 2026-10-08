package io.bearound.telemetry.bearound_telemetry_flutter_sdk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Before
import org.junit.Test

class DiscoveryContext

class CompanionTracking {
    fun getBusinessToken(): String? {
        getterCalls++
        if (getterThrows) throw IllegalStateException("Getter fixture failure")
        return token
    }

    companion object {
        val instance = CompanionTracking()
        var calls = 0
        var getterCalls = 0
        var received: DiscoveryContext? = null
        var token: String? = "configured"
        var factoryThrows = false
        var factoryReturnsNull = false
        var getterThrows = false

        fun getInstance(context: DiscoveryContext?): CompanionTracking? {
            calls++
            received = context
            if (factoryThrows) throw IllegalStateException("Factory fixture failure")
            return if (factoryReturnsNull) null else instance
        }
    }
}

object StaticTracking {
    var calls = 0
    var getterCalls = 0
    var received: DiscoveryContext? = null
    var token: String? = "configured"
    var factoryThrows = false
    var factoryReturnsNull = false
    var getterThrows = false

    @JvmStatic fun getInstance(context: DiscoveryContext?): StaticTracking? {
        calls++
        received = context
        if (factoryThrows) throw IllegalStateException("Factory fixture failure")
        return if (factoryReturnsNull) null else this
    }

    fun getBusinessToken(): String? {
        getterCalls++
        if (getterThrows) throw IllegalStateException("Getter fixture failure")
        return token
    }
}

class BothTracking {
    fun getBusinessToken(): String? {
        getterCalls++
        if (getterThrows) throw IllegalStateException("Getter fixture failure")
        return token
    }

    class AlternateFactory {
        fun getInstance(context: DiscoveryContext?): BothTracking {
            alternateCalls++
            alternateReceived = context
            return instance
        }
    }

    companion object Factory {
        @JvmField val Companion = AlternateFactory()
        val instance = BothTracking()
        var staticCalls = 0
        var alternateCalls = 0
        var getterCalls = 0
        var received: DiscoveryContext? = null
        var alternateReceived: DiscoveryContext? = null
        var token: String? = "configured"
        var factoryThrows = false
        var factoryReturnsNull = false
        var getterThrows = false

        @JvmStatic fun getInstance(context: DiscoveryContext?): BothTracking? {
            staticCalls++
            received = context
            if (factoryThrows) throw IllegalStateException("Factory fixture failure")
            return if (factoryReturnsNull) null else instance
        }
    }
}

object MissingGetterTracking {
    var calls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): MissingGetterTracking {
        calls++
        return this
    }
}

object WrongGetterTracking {
    var calls = 0
    var getterCalls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): WrongGetterTracking {
        calls++
        return this
    }
    fun getBusinessToken(): Int {
        getterCalls++
        return 7
    }
}

object StaticGetterTracking {
    var calls = 0
    var getterCalls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): StaticGetterTracking {
        calls++
        return this
    }
    @JvmStatic fun getBusinessToken(): String {
        getterCalls++
        return "configured"
    }
}

object ForeignFactoryTracking {
    var calls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): Any {
        calls++
        return "foreign instance"
    }
}

class MissingFactoryTracking {
    fun getBusinessToken(): String = "configured"
}

object WrongSignatureTracking {
    var calls = 0
    @JvmStatic fun getInstance(context: String): WrongSignatureTracking {
        calls++
        return this
    }
    fun getBusinessToken(): String = "configured"
}

class NonStaticFactoryTracking {
    fun getInstance(context: DiscoveryContext?): NonStaticFactoryTracking {
        calls++
        return this
    }
    fun getBusinessToken(): String = "configured"

    companion object {
        var calls = 0
        var alternateCalls = 0
        fun getInstance(context: DiscoveryContext?): NonStaticFactoryTracking {
            alternateCalls++
            return NonStaticFactoryTracking()
        }
    }
}

class NullCompanionTracking {
    companion object Factory {
        @JvmField val Companion: Any? = null
    }
}

class NonStaticCompanionTracking {
    @JvmField val Companion = CompanionTracking.Companion
}

class MissingCompanionFactoryTracking {
    companion object
}

class WrongCompanionSignatureTracking {
    companion object {
        var calls = 0
        fun getInstance(context: String): WrongCompanionSignatureTracking {
            calls++
            return WrongCompanionSignatureTracking()
        }
    }
}

object StaticCompanionFactory {
    var calls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): Any? {
        calls++
        return null
    }
}

class StaticCompanionMethodTracking {
    companion object Factory {
        @JvmField val Companion = StaticCompanionFactory
    }
}

object PrivateGetterTracking {
    var calls = 0
    var getterCalls = 0
    @JvmStatic fun getInstance(context: DiscoveryContext?): PrivateGetterTracking {
        calls++
        return this
    }
    private fun getBusinessToken(): String {
        getterCalls++
        return "configured"
    }
}

class TrackingSdkDiscoveryTest {
    private val context = DiscoveryContext()

    @Before fun resetFixtures() {
        CompanionTracking.calls = 0
        CompanionTracking.getterCalls = 0
        CompanionTracking.received = null
        CompanionTracking.token = "configured"
        CompanionTracking.factoryThrows = false
        CompanionTracking.factoryReturnsNull = false
        CompanionTracking.getterThrows = false
        StaticTracking.calls = 0
        StaticTracking.getterCalls = 0
        StaticTracking.received = null
        StaticTracking.token = "configured"
        StaticTracking.factoryThrows = false
        StaticTracking.factoryReturnsNull = false
        StaticTracking.getterThrows = false
        BothTracking.staticCalls = 0
        BothTracking.alternateCalls = 0
        BothTracking.getterCalls = 0
        BothTracking.received = null
        BothTracking.alternateReceived = null
        BothTracking.token = "configured"
        BothTracking.factoryThrows = false
        BothTracking.factoryReturnsNull = false
        BothTracking.getterThrows = false
        MissingGetterTracking.calls = 0
        WrongGetterTracking.calls = 0
        WrongGetterTracking.getterCalls = 0
        StaticGetterTracking.calls = 0
        StaticGetterTracking.getterCalls = 0
        ForeignFactoryTracking.calls = 0
        WrongSignatureTracking.calls = 0
        NonStaticFactoryTracking.calls = 0
        NonStaticFactoryTracking.alternateCalls = 0
        WrongCompanionSignatureTracking.calls = 0
        StaticCompanionFactory.calls = 0
        PrivateGetterTracking.calls = 0
        PrivateGetterTracking.getterCalls = 0
    }

    private fun discover(type: Class<*>): Any? =
        TrackingSdkDiscovery.configuredInstanceOrNull(context, DiscoveryContext::class.java) { type }

    @Test fun configuredCompanionOnlyReturnsOriginalInstanceWithOneFactoryCall() {
        assertSame(CompanionTracking.instance, discover(CompanionTracking::class.java))
        assertEquals(1, CompanionTracking.calls)
        assertEquals(1, CompanionTracking.getterCalls)
        assertSame(context, CompanionTracking.received)
    }

    @Test fun configuredStaticReturnsOriginalInstanceWithOneFactoryCall() {
        assertSame(StaticTracking, discover(StaticTracking::class.java))
        assertEquals(1, StaticTracking.calls)
        assertEquals(1, StaticTracking.getterCalls)
        assertSame(context, StaticTracking.received)
    }

    @Test fun staticFactoryTakesPrecedenceWithoutCallingCompanion() {
        assertSame(BothTracking.instance, discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(0, BothTracking.alternateCalls)
        assertEquals(1, BothTracking.getterCalls)
        assertSame(context, BothTracking.received)
        assertNull(BothTracking.alternateReceived)
    }

    @Test fun missingClassReturnsNullAfterOneClassLookup() {
        var calls = 0
        val instance = TrackingSdkDiscovery.configuredInstanceOrNull(context, DiscoveryContext::class.java) {
            calls++
            throw ClassNotFoundException("Missing tracking fixture")
        }
        assertNull(instance)
        assertEquals(1, calls)
    }

    @Test fun classLoaderFailureReturnsNullWithoutInitializingTracking() {
        assertNull(TrackingSdkDiscovery.configuredInstanceOrNull(context, DiscoveryContext::class.java) {
            throw LinkageError("Class loader fixture failure")
        })
        assertEquals(0, StaticTracking.calls)
    }

    @Test fun nullTokenRejectsTrackingAfterOneFactoryAndGetterCall() {
        StaticTracking.token = null
        assertNull(discover(StaticTracking::class.java))
        assertEquals(1, StaticTracking.calls)
        assertEquals(1, StaticTracking.getterCalls)
    }

    @Test fun emptyTokenRejectsTrackingWithoutCallingAlternateFactory() {
        BothTracking.token = ""
        assertNull(discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(1, BothTracking.getterCalls)
        assertEquals(0, BothTracking.alternateCalls)
    }

    @Test fun whitespaceTokenRejectsTrackingWithoutCallingAlternateFactory() {
        BothTracking.token = " \t\n"
        assertNull(discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(1, BothTracking.getterCalls)
        assertEquals(0, BothTracking.alternateCalls)
    }

    @Test fun throwingStaticFactoryReturnsNullWithoutCallingAlternateFactory() {
        BothTracking.factoryThrows = true
        assertNull(discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(0, BothTracking.getterCalls)
        assertEquals(0, BothTracking.alternateCalls)
    }

    @Test fun nullStaticFactoryReturnsNullWithoutCallingAlternateFactory() {
        BothTracking.factoryReturnsNull = true
        assertNull(discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(0, BothTracking.getterCalls)
        assertEquals(0, BothTracking.alternateCalls)
    }

    @Test fun throwingGetterReturnsNullWithoutCallingAlternateFactory() {
        BothTracking.getterThrows = true
        assertNull(discover(BothTracking::class.java))
        assertEquals(1, BothTracking.staticCalls)
        assertEquals(1, BothTracking.getterCalls)
        assertEquals(0, BothTracking.alternateCalls)
    }

    @Test fun missingPublicGetterRejectsTracking() {
        assertNull(discover(MissingGetterTracking::class.java))
        assertEquals(1, MissingGetterTracking.calls)
    }

    @Test fun wrongGetterTypeRejectsTrackingWithoutInvokingGetter() {
        assertNull(discover(WrongGetterTracking::class.java))
        assertEquals(1, WrongGetterTracking.calls)
        assertEquals(0, WrongGetterTracking.getterCalls)
    }

    @Test fun staticGetterRejectsTrackingWithoutInvokingGetter() {
        assertNull(discover(StaticGetterTracking::class.java))
        assertEquals(1, StaticGetterTracking.calls)
        assertEquals(0, StaticGetterTracking.getterCalls)
    }

    @Test fun foreignFactoryResultRejectsTracking() {
        assertNull(discover(ForeignFactoryTracking::class.java))
        assertEquals(1, ForeignFactoryTracking.calls)
    }

    @Test fun missingFactoryAndCompanionReturnsNull() {
        assertNull(discover(MissingFactoryTracking::class.java))
    }

    @Test fun unsupportedFactorySignatureReturnsNullWithoutInvocation() {
        assertNull(discover(WrongSignatureTracking::class.java))
        assertEquals(0, WrongSignatureTracking.calls)
    }

    @Test fun existingNonStaticFactoryRejectsTrackingWithoutCompanionInvocation() {
        assertNull(discover(NonStaticFactoryTracking::class.java))
        assertEquals(0, NonStaticFactoryTracking.calls)
        assertEquals(0, NonStaticFactoryTracking.alternateCalls)
    }

    @Test fun incompatibleContextTypeReturnsNullWithoutFactoryInvocation() {
        assertNull(TrackingSdkDiscovery.configuredInstanceOrNull(context, String::class.java) { StaticTracking::class.java })
        assertEquals(0, StaticTracking.calls)
    }

    @Test fun classProviderIsResolvedOnceForValidTracking() {
        var calls = 0
        val instance = TrackingSdkDiscovery.configuredInstanceOrNull(context, DiscoveryContext::class.java) {
            calls++
            StaticTracking::class.java
        }
        assertSame(StaticTracking, instance)
        assertEquals(1, calls)
        assertEquals(1, StaticTracking.calls)
    }

    @Test fun nullCompanionFieldRejectsTracking() {
        assertNull(discover(NullCompanionTracking::class.java))
        assertEquals(0, CompanionTracking.calls)
    }

    @Test fun nonStaticCompanionFieldRejectsTrackingWithoutFactoryInvocation() {
        assertNull(discover(NonStaticCompanionTracking::class.java))
        assertEquals(0, CompanionTracking.calls)
    }

    @Test fun missingCompanionFactoryRejectsTracking() {
        assertNull(discover(MissingCompanionFactoryTracking::class.java))
    }

    @Test fun unsupportedCompanionSignatureRejectsTrackingWithoutInvocation() {
        assertNull(discover(WrongCompanionSignatureTracking::class.java))
        assertEquals(0, WrongCompanionSignatureTracking.calls)
    }

    @Test fun staticMethodOnCompanionReceiverRejectsTrackingWithoutInvocation() {
        assertNull(discover(StaticCompanionMethodTracking::class.java))
        assertEquals(0, StaticCompanionFactory.calls)
    }

    @Test fun throwingCompanionFactoryReturnsNullAfterOneInvocation() {
        CompanionTracking.factoryThrows = true
        assertNull(discover(CompanionTracking::class.java))
        assertEquals(1, CompanionTracking.calls)
        assertEquals(0, CompanionTracking.getterCalls)
    }

    @Test fun nullCompanionFactoryReturnsNullAfterOneInvocation() {
        CompanionTracking.factoryReturnsNull = true
        assertNull(discover(CompanionTracking::class.java))
        assertEquals(1, CompanionTracking.calls)
        assertEquals(0, CompanionTracking.getterCalls)
    }

    @Test fun nullCompanionTokenRejectsOriginalTrackingInstance() {
        CompanionTracking.token = null
        assertNull(discover(CompanionTracking::class.java))
        assertEquals(1, CompanionTracking.calls)
        assertEquals(1, CompanionTracking.getterCalls)
    }

    @Test fun throwingCompanionGetterReturnsNullAfterOneInvocation() {
        CompanionTracking.getterThrows = true
        assertNull(discover(CompanionTracking::class.java))
        assertEquals(1, CompanionTracking.calls)
        assertEquals(1, CompanionTracking.getterCalls)
    }

    @Test fun nullContextIsPassedUnchangedToSelectedPublicFactory() {
        assertSame(StaticTracking, TrackingSdkDiscovery.configuredInstanceOrNull(null, DiscoveryContext::class.java) {
            StaticTracking::class.java
        })
        assertEquals(1, StaticTracking.calls)
        assertNull(StaticTracking.received)
    }

    @Test fun privateGetterIsNeverAccessedOrInvoked() {
        assertNull(discover(PrivateGetterTracking::class.java))
        assertEquals(1, PrivateGetterTracking.calls)
        assertEquals(0, PrivateGetterTracking.getterCalls)
    }
}
