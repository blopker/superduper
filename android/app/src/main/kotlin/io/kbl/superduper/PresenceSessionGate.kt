package io.kbl.superduper

internal data class PresenceSessionState(
    val synchronized: Boolean = false,
    val absentSinceMs: Long? = null,
)

internal data class PresenceAppearanceDecision(
    val state: PresenceSessionState,
    val shouldSynchronize: Boolean,
)

internal object PresenceSessionGate {
    fun onAppearance(state: PresenceSessionState): PresenceAppearanceDecision {
        if (!state.synchronized) {
            return PresenceAppearanceDecision(
                state = state.copy(absentSinceMs = null),
                shouldSynchronize = true,
            )
        }

        val confirmedNewSession = state.absentSinceMs != null
        return PresenceAppearanceDecision(
            state = PresenceSessionState(synchronized = !confirmedNewSession),
            shouldSynchronize = confirmedNewSession,
        )
    }

    fun onDisappearance(
        state: PresenceSessionState,
        nowMs: Long,
        credible: Boolean,
    ): PresenceSessionState {
        if (!credible || !state.synchronized) return state
        return state.copy(absentSinceMs = state.absentSinceMs ?: nowMs)
    }

    fun onConfirmed(state: PresenceSessionState): PresenceSessionState =
        state.copy(synchronized = true, absentSinceMs = null)
}
