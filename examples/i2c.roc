app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

address  = 0x0040

main =
    _ <- Task.attempt init
    Task.forever (Task.attempt run \_ -> Task.succeed {})

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    Pca9685.setPrescale address 121

run =
    _      <- await (Stdout.line "Enter the rotation amount (0 to 180):")
    amount <- await Stdin.line
    angle  <- await (Task.fromResult (Str.toF64 amount))
    _      <- await (setServoAngle 0 angle)
    _      <- await (setServoAngle 1 angle)
    _      <- await (setServoAngle 2 angle)
    Task.succeed {}

setServoAngle = \servo, angle ->
    count = map angle 0 180 145 500 |> Num.floor
    Pca9685.setPinOffTicks address servo count

map = \value, inMin, inMax, outMin, outMax -> (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin

