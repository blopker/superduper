package io.kbl.superduper

/** Authenticated history inspection and receipt verification for one control command. */
internal class BackgroundControlSync(command: ByteArray) {
    sealed interface Action {
        data class Select(val selector: ByteArray) : Action
        data class Read(val delayMs: Long = 100L) : Action
        data class Write(val command: ByteArray) : Action
        data class Complete(val applied: Boolean) : Action
        data class Failed(val detail: String) : Action
    }

    private enum class Stage {
        SELECT_BARRIER, READ_BARRIER, SELECT_CONTROL, READ_CONTROL, WRITE, FINISHED,
    }

    private val markedCommand = command.copyOf().also {
        require(
            it.size == 10 && it[0] == 0.toByte() &&
                (it[1] == 0xd1.toByte() || it[1] == 0xc1.toByte()),
        ) {
            "Background Sync requires a V1 or V2 control command"
        }
        // Startup seeds this history record with zeroes. All app control writes
        // use byte 5 = 1 so reconnects cannot reapply settings in the same session.
        it[5] = 1
    }
    private var stage = Stage.SELECT_BARRIER
    private var verifying = false
    private var reads = 0

    fun start(): Action = Action.Select(byteArrayOf(0xfc.toByte(), 0xfc.toByte()))

    fun onWrite(): Action = when (stage) {
        Stage.SELECT_BARRIER -> {
            stage = Stage.READ_BARRIER
            reads = 0
            Action.Read()
        }
        Stage.SELECT_CONTROL -> {
            stage = Stage.READ_CONTROL
            reads = 0
            Action.Read()
        }
        Stage.WRITE -> {
            verifying = true
            stage = Stage.SELECT_BARRIER
            start()
        }
        else -> error("Unexpected control transaction write completion")
    }

    fun onRead(value: ByteArray): Action {
        check(stage == Stage.READ_BARRIER || stage == Stage.READ_CONTROL)
        val expectedId = if (stage == Stage.READ_BARRIER) {
            byteArrayOf(0xfc.toByte(), 0xfc.toByte())
        } else {
            markedCommand.copyOfRange(0, 2)
        }
        val matches = value.size == 10 && value[0] == expectedId[0] && value[1] == expectedId[1]
        val receiptMismatch = stage == Stage.READ_CONTROL && verifying && !value.contentEquals(markedCommand)
        if (!matches || receiptMismatch) {
            reads++
            if (reads < 20) return Action.Read()
            stage = Stage.FINISHED
            return Action.Failed("Could not verify the selected bike history record")
        }
        if (stage == Stage.READ_BARRIER) {
            stage = Stage.SELECT_CONTROL
            return Action.Select(markedCommand.copyOfRange(0, 2))
        }
        if (verifying || value[5] == 1.toByte()) {
            stage = Stage.FINISHED
            return Action.Complete(applied = verifying)
        }
        stage = Stage.WRITE
        return Action.Write(markedCommand.copyOf())
    }
}
