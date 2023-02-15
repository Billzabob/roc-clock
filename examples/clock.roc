app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [0x0040, 0x0041]

main =
    _ <- Task.await init
    Task.forever run

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    address <- traverse addresses
    Pca9685.setPrescale address 121

run =
    _ <- await (Stdout.line "Set number:")
    n <- await Stdin.line
    v = getSegments n
    setNumber 0x0040 0 v

setNumber = \address, offset, segments ->
    segment <- traverse (List.mapWithIndex segments \segment, index -> F (index + offset) segment)
    when T address segment is
        T 0x0040 (F 0 On) -> Pca9685.setPinOffTicks 0x0040 0 355
        T 0x0040 (F 0 Off) -> Pca9685.setPinOffTicks 0x0040 0 170
        T 0x0040 (F 1 On) -> Pca9685.setPinOffTicks 0x0040 1 190
        T 0x0040 (F 1 Off) -> Pca9685.setPinOffTicks 0x0040 1 365
        T 0x0040 (F 2 On) -> Pca9685.setPinOffTicks 0x0040 2 370
        T 0x0040 (F 2 Off) -> Pca9685.setPinOffTicks 0x0040 2 180
        T 0x0040 (F 3 On) -> Pca9685.setPinOffTicks 0x0040 3 390
        T 0x0040 (F 3 Off) -> Pca9685.setPinOffTicks 0x0040 3 200
        T 0x0040 (F 4 On) -> Pca9685.setPinOffTicks 0x0040 4 380
        T 0x0040 (F 4 Off) -> Pca9685.setPinOffTicks 0x0040 4 190
        T 0x0040 (F 5 On) -> Pca9685.setPinOffTicks 0x0040 5 190
        T 0x0040 (F 5 Off) -> Pca9685.setPinOffTicks 0x0040 5 390
        T 0x0040 (F 6 On) -> Pca9685.setPinOffTicks 0x0040 6 170
        T 0x0040 (F 6 Off) -> Pca9685.setPinOffTicks 0x0040 6 360
        T 0x0040 (F 8 On) -> Pca9685.setPinOffTicks 0x0040 8 430
        T 0x0040 (F 8 Off) -> Pca9685.setPinOffTicks 0x0040 8 230
        T 0x0040 (F 9 On) -> Pca9685.setPinOffTicks 0x0040 9 220
        T 0x0040 (F 9 Off) -> Pca9685.setPinOffTicks 0x0040 9 400
        T 0x0040 (F 10 On) -> Pca9685.setPinOffTicks 0x0040 10 400
        T 0x0040 (F 10 Off) -> Pca9685.setPinOffTicks 0x0040 10 220
        T 0x0040 (F 11 On) -> Pca9685.setPinOffTicks 0x0040 11 420
        T 0x0040 (F 11 Off) -> Pca9685.setPinOffTicks 0x0040 11 230
        T 0x0040 (F 12 On) -> Pca9685.setPinOffTicks 0x0040 12 390
        T 0x0040 (F 12 Off) -> Pca9685.setPinOffTicks 0x0040 12 220
        T 0x0040 (F 13 On) -> Pca9685.setPinOffTicks 0x0040 13 240
        T 0x0040 (F 13 Off) -> Pca9685.setPinOffTicks 0x0040 13 420
        T 0x0040 (F 14 On) -> Pca9685.setPinOffTicks 0x0040 14 230
        T 0x0040 (F 14 Off) -> Pca9685.setPinOffTicks 0x0040 14 420
        _ -> crash "Foo"

getSegments = \n ->
    when n is
        "0" -> [On, On, On, Off, On, On, On]
        "1" -> [Off, Off, On, Off, Off, On, Off]
        "2" -> [On, Off, On, On, On, Off, On]
        "3" -> [On, Off, On, On, Off, On, On]
        "4" -> [Off, On, On, On, Off, On, Off]
        "5" -> [On, On, Off, On, Off, On, On]
        "6" -> [On, On, Off, On, On, On, On]
        "7" -> [On, Off, On, Off, Off, On, Off]
        "8" -> [On, On, On, On, On, On, On]
        "9" -> [On, On, On, On, Off, On, Off]
        _ -> crash "Invalid digit"

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

