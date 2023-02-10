app "i2c"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.Stdin, pf.I2c, pf.Task.{ Task, await }]
    provides [main] to pf

address  = 0x0040
mode1    = 0
prescale = 254
sleepBit = 0x10

main =
    _ <- Task.attempt init
    Task.forever (Task.attempt run \_ -> Task.succeed {})

init =
    _ <- await (reset)
    # About 50 Hz
    setPrescale 121

run =
    _      <- await (Stdout.line "Enter the rotation amount (0 to 180):")
    amount <- await Stdin.line
    angle  <- await (Task.fromResult (Str.toF64 amount))
    _      <- await (setServoAngle 0 angle)
    _      <- await (setServoAngle 1 angle)
    _      <- await (setServoAngle 2 angle)
    Task.succeed {}

setServoAngle = \servo, angle ->
    register = 4 * servo + 8
    count = map angle 0 180 145 500 |> Num.floor
    low = Num.bitwiseAnd count 0xff |> Num.toU8
    high = Num.shiftRightZfBy count 8 |> Num.toU8
    _ <- await (writeRegister register low)
    _ <- await (writeRegister (register + 1) high)
    Task.succeed {}

setPrescale = \value ->
    _ <- await sleep
    _ <- await (writeRegister prescale value)
    _ <- await wakeup
    Gpio.sleep 5

readRegister = \register ->
    _     <- await (I2c.writeBytes address [register])
    bytes <- await (I2c.readBytes address 1)
    Task.fromResult (List.get bytes 0)

writeRegister = \register, value ->
    I2c.writeBytes address [register, value]

sleep =
    oldMode <- await (readRegister mode1)
    newMode = Num.bitwiseOr oldMode sleepBit
    writeRegister mode1 newMode

wakeup =
    oldMode <- await (readRegister mode1)
    newMode = sleepBit |> bitwiseNot |> Num.bitwiseAnd oldMode
    writeRegister mode1 newMode

bitwiseNot = \bits -> Num.bitwiseXor 0xff bits

reset = I2c.writeBytes 0 [0x06]

map = \value, inMin, inMax, outMin, outMax -> (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin

