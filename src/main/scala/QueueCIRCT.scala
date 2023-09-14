package example

import chisel3._
import chisel3.util.Queue
import circt.stage.ChiselStage

object QueueUIntCIRCTApp extends App {
  ChiselStage.emitSystemVerilog(new Queue(UInt(16.W), 2, pipe = true))
}

object QueueSIntCIRCTApp extends App {
  ChiselStage.emitSystemVerilog(new Queue(SInt(16.W), 2, pipe = true))
}