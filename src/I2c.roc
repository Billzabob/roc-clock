interface I2c
    exposes [writeByte, readByte]
    imports [Effect, Task.{ Task }, InternalTask]

writeByte : U16, U8 -> Task {} [WriteFailure]
writeByte = \address, byte ->
    Effect.writeByte address byte
    |> Effect.map (\result -> Result.mapErr result \{} -> WriteFailure)
    |> InternalTask.fromEffect

readByte = \address ->
    Effect.readByte address
    |> Effect.map Ok
    |> InternalTask.fromEffect

