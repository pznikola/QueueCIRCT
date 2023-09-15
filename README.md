# Queue example

The Queue code example is the simplified example of problem stated [here](https://github.com/milovanovic/chipyard/tree/1.9.0_queue). The scala code for this example can be found [here](./src/main/scala/QueueExample.scala).


For UInt Queue, verilog will be succesfully generated but for SInt Queue verilog generation will fail with following error:
```scala
Decoupled.scala:274:95: error: memories should be flattened before running LowerMemory
Decoupled.scala:274:95: note: see current operation: %5:2 = "firrtl.mem"() {annotations = [], depth = 1024 : i64, name = "ram", nameKind = #firrtl<name_kind droppable_name>, portAnnotations = [[], []], portNames = ["MPORT", "io_deq_bits_MPORT"], readLatency = 0 : i32, ruw = 0 : i32, writeLatency = 1 : i32} : () -> (!firrtl.bundle<addr: uint<10>, en: uint<1>, clk: clock, data: sint<16>, mask: uint<1>>, !firrtl.bundle<addr: uint<10>, en: uint<1>, clk: clock, data flip: sint<16>>)

```
To reporoduce this error, run:
```bash
make sint # for SInt Queue. Error expected
```
or
```bash
make uint # for UInt Queue. Should be succesfull
```

The makeflow  used in this example is based on the [common.mk](https://github.com/ucb-bar/chipyard/blob/main/common.mk) from chipyard.