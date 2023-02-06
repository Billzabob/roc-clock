interface Gpio
    exposes [setPinHigh, setPinLow, sleep, pwm]
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

pwm : F64, F64 -> Task {} *
pwm = \frequency, dutyCycle ->
    Effect.pwm frequency dutyCycle
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect
