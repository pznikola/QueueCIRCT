package example

import chisel3._
import chisel3.util.Queue
import circt.stage.ChiselStage

import java.io._

object QueueUIntChirtlApp extends App {
    // Write output data to text file
    val directory = new File("./test_and_run");
    if (! directory.exists()){
        directory.mkdir();
    }
    val file = new File("./test_and_run/Queue.fir")
    val w = new BufferedWriter(new FileWriter(file))
    w.write(ChiselStage.emitCHIRRTL(new Queue(UInt(16.W), 1024, pipe = true)))
    w.close
}

object QueueSIntChirtlApp extends App {
    // Write output data to text file
    val directory = new File("./test_and_run");
    if (! directory.exists()){
        directory.mkdir();
    }
    val file = new File("./test_and_run/Queue.fir")
    val w = new BufferedWriter(new FileWriter(file))
    w.write(ChiselStage.emitCHIRRTL(new Queue(SInt(16.W), 1024, pipe = true)))
    w.close
}