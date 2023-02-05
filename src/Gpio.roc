interface Gpio
    exposes [setPinHigh, setPinLow, sleep]
    imports [Effect, Task.{ Task }, InternalTask]

setPinLow : U8 -> Task {} [GpioFailure]
setPinLow = \pin ->
    Effect.setPinLow pin
    |> Effect.map (\result -> Result.mapErr result \{} -> GpioFailure)
    |> InternalTask.fromEffect

setPinHigh : U8 -> Task {} [GpioFailure]
setPinHigh = \pin ->
    Effect.setPinHigh pin
    |> Effect.map (\result -> Result.mapErr result \{} -> GpioFailure)
    |> InternalTask.fromEffect

sleep : U64 -> Task {} *
sleep = \duration ->
    Effect.sleep duration
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect
