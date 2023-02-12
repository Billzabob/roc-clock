app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

address  = 0x0040
pins1 = [8, 10, 11, 12]

main =
    _ <- Task.attempt init
    Task.forever (Task.attempt run \_ -> Task.succeed {})

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    Pca9685.setPrescale address 121

run =
    _      <- await (setFoo 8 Off)
    _      <- await (setFoo 9 Off)
    _      <- await (setFoo 10 Off)
    _      <- await (setFoo 11 Off)
    _      <- await (setFoo 12 Off)
    _      <- await (setFoo 13 Off)
    _      <- await (setFoo 14 Off)
    _      <- await (Stdout.line "Enter the rotation amount (0 to 180):")
    amount <- await Stdin.line
    angle  <- await (Task.fromResult (Str.toF64 amount))
    _      <- await (setServoAngle 0 angle)
    Task.succeed {}

setFoo : U8, [On, Off] -> Task {} *
setFoo = \pin, state ->
    angle =
        if List.contains pins1 pin then
            when state is
                On  -> 135
                Off -> 45
        else
            when state is
                On  -> 45
                Off -> 135
    count = map angle 0 180 145 500 |> Num.floor
    Pca9685.setPinOffTicks address pin count

setServoAngle = \servo, angle ->
    count = map angle 0 180 145 500 |> Num.floor
    Pca9685.setPinOffTicks address servo count

map = \value, inMin, inMax, outMin, outMax -> (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin

