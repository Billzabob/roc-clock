interface Gpio
    exposes [setPinHigh, setPinLow, pwm]
    imports [Effect, Task.{ Task }, InternalTask]

setPinLow : U8 -> Task {} *
setPinLow = \pin ->
    Effect.setPinLow pin
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect

setPinHigh : U8 -> Task {} *
setPinHigh = \pin ->
    Effect.setPinHigh pin
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect

pwm : F64, F64 -> Task {} *
pwm = \frequency, dutyCycle ->
    Effect.pwm frequency dutyCycle
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect

