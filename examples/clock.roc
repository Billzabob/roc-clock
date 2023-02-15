app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [64, 65]
digits = [{ address: 64, offset: 0 }, { address: 64, offset: 8 }] #, { address: 65, offset: 0 }, { address: 65, offset: 8 }]

main =
    _ <- Task.await init
    Task.forever run

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    address <- traverse addresses
    Pca9685.setPrescale address 121

run =
    _ <- await (Stdout.line "Set 2 digit number:")
    n <- await Stdin.line
    numbers = Str.graphemes n
    objects = numbers |> zip digits \num, d -> { value: num, digits: d }
    object <- traverse objects
    colors = getSegments object.value
    setNumber object.digits.address object.digits.offset colors

setNumber : U16, U8, List [White, Black] -> Task (List {}) []
setNumber = \address, offse, colors ->
    color <- traverse (List.mapWithIndex colors \segment, i -> { index: (offse + (Num.toU8 i)), segment })
    amount = getCalibration { address, pin: color.index, color: color.segment }
    Pca9685.setPinOffTicks address color.index amount

getCalibration = \input ->
    when input is
        { address: 64, pin: 0,  color: Black } -> 355
        { address: 64, pin: 0,  color: White } -> 170
        { address: 64, pin: 1,  color: Black } -> 190
        { address: 64, pin: 1,  color: White } -> 365
        { address: 64, pin: 2,  color: Black } -> 370
        { address: 64, pin: 2,  color: White } -> 180
        { address: 64, pin: 3,  color: Black } -> 390
        { address: 64, pin: 3,  color: White } -> 200
        { address: 64, pin: 4,  color: Black } -> 380
        { address: 64, pin: 4,  color: White } -> 190
        { address: 64, pin: 5,  color: Black } -> 190
        { address: 64, pin: 5,  color: White } -> 390
        { address: 64, pin: 6,  color: Black } -> 170
        { address: 64, pin: 6,  color: White } -> 360
        { address: 64, pin: 8,  color: Black } -> 430
        { address: 64, pin: 8,  color: White } -> 230
        { address: 64, pin: 9,  color: Black } -> 220
        { address: 64, pin: 9,  color: White } -> 400
        { address: 64, pin: 10, color: Black } -> 400
        { address: 64, pin: 10, color: White } -> 220
        { address: 64, pin: 11, color: Black } -> 420
        { address: 64, pin: 11, color: White } -> 230
        { address: 64, pin: 12, color: Black } -> 390
        { address: 64, pin: 12, color: White } -> 220
        { address: 64, pin: 13, color: Black } -> 240
        { address: 64, pin: 13, color: White } -> 420
        { address: 64, pin: 14, color: Black } -> 230
        { address: 64, pin: 14, color: White } -> 420
        _ -> crash "No calibration"

getSegments = \n ->
    when n is
        "0" -> [Black, Black, Black, White, Black, Black, Black]
        "1" -> [White, White, Black, White, White, Black, White]
        "2" -> [Black, White, Black, Black, Black, White, Black]
        "3" -> [Black, White, Black, Black, White, Black, Black]
        "4" -> [White, Black, Black, Black, White, Black, White]
        "5" -> [Black, Black, White, Black, White, Black, Black]
        "6" -> [Black, Black, White, Black, Black, Black, Black]
        "7" -> [Black, White, Black, White, White, Black, White]
        "8" -> [Black, Black, Black, Black, Black, Black, Black]
        "9" -> [Black, Black, Black, Black, White, Black, White]
        _ -> crash "Invalid digit"

zip : List a, List b, (a, b -> c) -> List c
zip = \list1, list2, f ->
    list1
    |> List.mapWithIndex \a, i ->
        when List.get list2 i is
            Ok b -> f a b
            Err OutOfBounds -> crash "Lists must be same length to zip"

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

