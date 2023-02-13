app "calibrate"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [0x0040, 0x0041]
offsets = [0, 8]
pins = List.range { start: At 0, end: Length 7 }
#pins1 = [0, 2, 3, 4]

main : Task {} []
main =
    _ <- Task.attempt init
    _ <- await run
    Task.succeed {}

init =
    _ <- await (Pca9685.reset)
    address <- traverse addresses
    # About 50 Hz
    Pca9685.setPrescale address 121

segments : List { address : U16, pin : U8 }
segments =
    address <- List.joinMap addresses
    offset <- List.joinMap offsets
    pin <- List.map pins
    { address, pin: pin + offset }

run : Task (List {}) []
run =
    segment <- traverse segments
    _ <- await (Stdout.line "Set the max")
    _ <- await (Pca9685.setPinOffTicks segment.address segment.pin 500)
    setVal 500 segment.address segment.pin

setVal : U16, U16, U8 -> Task {} []
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
            Ok _v -> Task.succeed {} # setVal v address pin
            Err _ -> Task.succeed {} # setVal value address pin

traverse : List a, (a -> Task b err) -> Task (List b) err
traverse = \list, f ->
    initialState = Task.succeed (List.withCapacity (List.len list))
    walker = \task, elem -> map2 task (f elem) List.append
    List.walk list initialState walker

map2 : Task a err, Task b err, (a, b -> c) -> Task c err
map2 = \task1, task2, f ->
    a <- await task1
    b <- await task2
    Task.succeed (f a b)

