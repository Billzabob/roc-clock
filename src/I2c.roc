interface I2c
    exposes [writeBytes, readBytes]
    imports [Effect, Task.{ Task }, InternalTask]

writeBytes : U16, List U8 -> Task {} *
writeBytes = \address, bytes ->
    Effect.writeBytes address bytes
    |> Effect.map Ok
    |> InternalTask.fromEffect

readBytes : U16, Nat -> Task (List U8) *
readBytes = \address, size ->
    Effect.readBytes address size
    |> Effect.map Ok
    |> InternalTask.fromEffect

