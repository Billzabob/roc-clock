interface Pca9685
    exposes [setPinOnTicks, setPinOffTicks, setPrescale, readRegister, writeRegister, sleep, wakeup, reset]
    imports [Task.{ Task, await }, I2c]

mode1    = 0
sleepBit = 0x10
prescale = 254

setPinOnTicks : U16, U8, U16 -> Task {} *
setPinOnTicks = \address, pin, ticks ->
    register = 4 * pin + 6
    low = Num.bitwiseAnd ticks 0xff |> Num.toU8
    high = Num.shiftRightZfBy ticks 8 |> Num.toU8
    _ <- await (writeRegister address register low)
    _ <- await (writeRegister address (register + 1) high)
    Task.succeed {}

setPinOffTicks : U16, U8, U16 -> Task {} *
setPinOffTicks = \address, pin, ticks ->
    register = 4 * pin + 8
    low = Num.bitwiseAnd ticks 0xff |> Num.toU8
    high = Num.shiftRightZfBy ticks 8 |> Num.toU8
    _ <- await (writeRegister address register low)
    _ <- await (writeRegister address (register + 1) high)
    Task.succeed {}

setPrescale : U16, U8 -> Task {} []
setPrescale = \address, value ->
    _ <- await (sleep address)
    _ <- await (writeRegister address prescale value)
    wakeup address

readRegister : U16, U8 -> Task U8 []
readRegister = \address, register ->
    _     <- await (I2c.writeBytes address [register])
    bytes <- Task.map (I2c.readBytes address 1)
    when bytes is
        [h] -> h
        _ -> crash "Asked for 1 byte and didn't receive 1 byte in readRegister"

writeRegister : U16, U8, U8 -> Task {} *
writeRegister = \address, register, value ->
    I2c.writeBytes address [register, value]

sleep : U16 -> Task {} []
sleep = \address ->
    oldMode <- await (readRegister address mode1)
    newMode = Num.bitwiseOr oldMode sleepBit
    writeRegister address mode1 newMode

wakeup : U16 -> Task {} []
wakeup = \address ->
    oldMode <- await (readRegister address mode1)
    newMode = sleepBit |> bitwiseNot |> Num.bitwiseAnd oldMode
    _ <- await (writeRegister address mode1 newMode)
    Task.sleep 5

reset : Task {} *
reset = I2c.writeBytes 0 [0x06]

bitwiseNot = \bits -> Num.bitwiseXor 0xff bits

