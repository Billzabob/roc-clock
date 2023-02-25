app "clock"
    packages { pf: "../src/main.roc" }
    imports [pf.Time, pf.Pca9685, pf.Task.{ Task, await }]
    provides [main] to pf

addresses = [64, 65]
pins = [{ address: 65, offset: 0 }, { address: 65, offset: 8 }, { address: 64, offset: 0 }, { address: 64, offset: 8 }]
segments = { start: At 0, end: Length 7 } |> List.range |> List.reverse

main =
    _ <- await init
    _ <- await startup
    Task.loop ["8", "8", "8", "8"] run

init =
    _ <- await (Pca9685.reset)
    # About 50 Hz
    address <- Task.traverse addresses
    Pca9685.setPrescale address 121

run = \lastNumbers ->
    _ <- await (Task.sleep 1000)
    n <- await Time.getTime
    numbers = Str.graphemes n
    _ <- await (setClock lastNumbers numbers)
    Task.succeed (Step numbers)

setClock = \lastNumbers, numbers ->
    updates = numbers |> List.map3 lastNumbers pins \number, lastNumber, pin -> { number, lastNumber, pin }
    collisions <- await (handleCollisions updates)
    _ <- await (if List.any collisions \collision -> collision == Collision then Task.sleep 300 else Task.succeed {})
    _ <- await (setNumbers updates)
    Task.succeed {}

handleCollisions = \updates ->
    { number, lastNumber, pin } <- Task.traverse updates
    if checkCollision lastNumber number then
        _ <- await (avoidCollision pin)
        Task.succeed Collision
    else
        Task.succeed NoCollision

setNumbers = \updates ->
    { number, pin } <- Task.traverse updates
    colors = getSegments number
    setNumber pin.address pin.offset colors


checkCollision = \lastNumber, number ->
    collisions = [
        T "1" "2",
        T "2" "0",
        T "2" "1",
        T "3" "0",
        T "5" "0",
        T "7" "8",
        T "8" "0",
        T "8" "1",
        T "8" "7",
        T "9" "0"
    ]
    List.contains collisions (T lastNumber number)

avoidCollision = \{ address, offset } ->
    amount1 = getCalibration { address, pin: offset + 1, color: White }
    amount2 = getCalibration { address, pin: offset + 2, color: White }
    _ <- await (Pca9685.setPinOffTicks address (offset + 1) amount1)
    _ <- await (Pca9685.setPinOffTicks address (offset + 2) amount2)
    Task.succeed {}

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

