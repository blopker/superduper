package io.kbl.superduper

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PresenceSessionGateTest {
    @Test
    fun firstAppearanceStartsSynchronization() {
        val decision = PresenceSessionGate.onAppearance(PresenceSessionState())

        assertTrue(decision.shouldSynchronize)
        assertFalse(decision.state.synchronized)
        assertNull(decision.state.absentSinceMs)
    }

    @Test
    fun confirmedSessionIgnoresDuplicateAppearances() {
        val state = PresenceSessionGate.onConfirmed(PresenceSessionState())

        val decision = PresenceSessionGate.onAppearance(state)

        assertFalse(decision.shouldSynchronize)
        assertTrue(decision.state.synchronized)
        assertNull(decision.state.absentSinceMs)
    }

    @Test
    fun confirmedDisappearanceCreatesANewSessionImmediately() {
        val confirmed = PresenceSessionGate.onConfirmed(PresenceSessionState())
        val absent = PresenceSessionGate.onDisappearance(
            confirmed,
            nowMs = 10_000,
            credible = true,
        )

        val decision = PresenceSessionGate.onAppearance(absent)

        assertTrue(decision.shouldSynchronize)
        assertFalse(decision.state.synchronized)
        assertNull(decision.state.absentSinceMs)
    }

    @Test
    fun transactionDisappearanceDoesNotCreateANewSession() {
        val confirmed = PresenceSessionGate.onConfirmed(PresenceSessionState())

        val state = PresenceSessionGate.onDisappearance(
            confirmed,
            nowMs = 10_000,
            credible = false,
        )

        assertTrue(state.synchronized)
        assertNull(state.absentSinceMs)
    }
}
