app "calibrate"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [0x0040, 0x0041]
offsets = [0, 8]
pins = [0, 1, 2, 3, 4, 5, 6]
pins1 = [0, 2, 3, 4]

main =
    _ <- Task.attempt init
    run

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    # TODO traverse
    _ <- await (Pca9685.setPrescale 0x0040 121)
    _ <- await (Pca9685.setPrescale 0x0041 121)
    Task.succeed {}

run =
    address <- List.map addresses
    offset <- List.map offsets
    pin <- List.map pins
    _ <- await (Stdout.line "Set the max")
    _ <- await (Pca9685.setPinOffTicks address (pin + offset) 500)
    Task.succeed {}

setVal = \value, address, pin ->
    _ <- await (Pca9685.setPinOffTicks address pin value)
    _ <- await (Stdout.line "How is this?")
    a <- await Stdin.line
    if a == "next" then
        addressStr = Num.toStr address
        pinStr = Num.toStr pin
        valueStr = Num.toStr value
        Stdout.line "Set address \(addressStr) and pin \(pinStr) to value: \(valueStr)"
    else
        when Str.toU16 a is
            Ok v  -> setVal v address pin
            Err _ -> setVal value address pin
    

# count = map angle 0 180 145 500 |> Num.floor

