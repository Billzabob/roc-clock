app "calibrate"
    packages { pf: "../src/main.roc" }
    imports [pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

#addresses = [0x0040, 0x0041]
#offsets = [0, 8]
#pins = List.range { start: At 0, end: Length 7 }

main : Task {} []
main =
    _ <- Task.attempt init
#    _ <- await run
#    _ <- await (Pca9685.setPinOffTicks 0x0040 1 2)
    Task.succeed {}

init : Task {} [OutOfBounds]
init =
    _ <- await (Pca9685.reset)
#    address <- traverse addresses
#    # About 50 Hz
    Pca9685.setPrescale 0x0040 121

#segments : List { address : U16, pin : U8 }
#segments =
#    address <- List.joinMap addresses
#    offset <- List.joinMap offsets
#    pin <- List.map pins
#    { address, pin: pin + offset }

#run : Task (List {}) []
#run =
#    _segment <- traverse segments
#    Task.succeed {}

#traverse : List a, (a -> Task b err) -> Task (List b) err
#traverse = \list, f ->
#    initialState = Task.succeed (List.withCapacity (List.len list))
#    walker = \task, elem -> map2 task (f elem) List.append
#    List.walk list initialState walker

#map2 : Task a err, Task b err, (a, b -> c) -> Task c err
#map2 = \task1, task2, f ->
#    a <- await task1
#    b <- await task2
#    Task.succeed (f a b)

