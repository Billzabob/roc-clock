app "calibrate"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [0x0040, 0x0041]
offsets = [0, 8]
pins = List.range { start: At 0, end: Length 7 }

main : Task {} []
main =
    _ <- await init
    _ <- await run
    Task.succeed {}

init : Task (List {}) []
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
    setSegment segment 330

setSegment : { address : U16, pin : U8 }, U16 -> Task {} []
setSegment = \segment, value ->
    str = Num.toStr value
    addr = Num.toStr segment.address
    pin = Num.toStr segment.pin
    _ <- await (Stdout.line "Setting addr \(addr) and pin \(pin) to \(str). New value or next?")
    _ <- await (Pca9685.setPinOffTicks segment.address segment.pin value)
    resp <- await Stdin.line
    if resp == "next" then
        Task.succeed {}
    else
        when Str.toU16 resp is
            Ok v -> setSegment segment v
            Err InvalidNumStr -> setSegment segment value

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

