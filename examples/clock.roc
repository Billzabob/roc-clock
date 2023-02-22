app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [64, 65]
pins = [{ address: 65, offset: 0 }, { address: 65, offset: 8 }, { address: 64, offset: 0 }, { address: 64, offset: 8 }]
segments = { start: At 0, end: Length 7 } |> List.range |> List.reverse

main =
    _ <- await init
    _ <- await startup
    Task.forever run

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    address <- Task.traverse addresses
    Pca9685.setPrescale address 121

run =
    _ <- await (Stdout.line "Set 4 digit number:")
    n <- await Stdin.line
    _ <- await empty
    _ <- await (Task.sleep 700)
    numbers = Str.graphemes n
    updates = numbers |> List.map2 pins \number, pin -> { number, pin }
    { number, pin } <- Task.traverse updates
    colors = getSegments number
    setNumber pin.address pin.offset colors

setNumber = \address, offset, colors ->
    color <- Task.traverse (List.mapWithIndex colors \segment, i -> { index: (offset + (Num.toU8 i)), segment })
    amount = getCalibration { address, pin: color.index, color: color.segment }
    Pca9685.setPinOffTicks address color.index amount

startup =
    _ <- await empty
    _ <- await (Task.sleep 700)
    startupSequence

empty =
    segment <- Task.traverse segments
    setSegmentForEachDigit segment White

startupSequence =
    segment <- Task.traverse segments
    _ <- await (setSegmentForEachDigit segment Black)
    Task.sleep 300

setSegmentForEachDigit = \segment, color ->
    { address, offset } <- Task.traverse pins
    pin = segment + offset
    amount = getCalibration { address, pin, color }
    Pca9685.setPinOffTicks address pin amount

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
        { address: 65, pin: 0,  color: Black } -> 340
        { address: 65, pin: 0,  color: White } -> 150
        { address: 65, pin: 1,  color: Black } -> 180
        { address: 65, pin: 1,  color: White } -> 350
        { address: 65, pin: 2,  color: Black } -> 380
        { address: 65, pin: 2,  color: White } -> 210
        { address: 65, pin: 3,  color: Black } -> 370
        { address: 65, pin: 3,  color: White } -> 180
        { address: 65, pin: 4,  color: Black } -> 380
        { address: 65, pin: 4,  color: White } -> 180
        { address: 65, pin: 5,  color: Black } -> 190
        { address: 65, pin: 5,  color: White } -> 370
        { address: 65, pin: 6,  color: Black } -> 190
        { address: 65, pin: 6,  color: White } -> 370
        { address: 65, pin: 8,  color: Black } -> 380
        { address: 65, pin: 8,  color: White } -> 200
        { address: 65, pin: 9,  color: Black } -> 180
        { address: 65, pin: 9,  color: White } -> 350
        { address: 65, pin: 10, color: Black } -> 340
        { address: 65, pin: 10, color: White } -> 170
        { address: 65, pin: 11, color: Black } -> 320
        { address: 65, pin: 11, color: White } -> 150
        { address: 65, pin: 12, color: Black } -> 370
        { address: 65, pin: 12, color: White } -> 200
        { address: 65, pin: 13, color: Black } -> 170
        { address: 65, pin: 13, color: White } -> 340
        { address: 65, pin: 14, color: Black } -> 160
        { address: 65, pin: 14, color: White } -> 340
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

