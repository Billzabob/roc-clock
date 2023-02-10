app "i2c"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.I2c, pf.Task.{ Task, await }]
    provides [main] to pf

address = 0x0040
mode1 = 0
prescale = 254
sleepBit = 0x10
# led0OnL = 6
# led0OnH = 7
led0OffL = 8
led0OffH = 9

main : Task {} []
main =
    result <- Task.attempt run
    when result is
        Ok _ -> Stdout.line "Success"
        Err _ -> Stdout.line "Failure"

run =
    _ <- await (readAndPrint prescale)
    _ <- await (reset)
    _ <- await (Gpio.sleep 5)
    _ <- await (readAndPrint prescale)
    _ <- await (setPrescale 121)
    _ <- await (readAndPrint prescale)
    _ <- await (writeRegister led0OffL 51)
    _ <- await (writeRegister led0OffH 1)
    _ <- await (readAndPrint 8)
    _ <- await (readAndPrint 9)
    Task.succeed {}

setPrescale = \value ->
    _ <- await sleep
    _ <- await (writeRegister prescale value)
    _ <- await wakeup
    Gpio.sleep 5

readRegister = \register ->
    _ <- await (I2c.writeBytes address [register])
    bytes <- await (I2c.readBytes address 1)
    Task.fromResult (List.get bytes 0)

writeRegister = \register, value ->
    I2c.writeBytes address [register, value]
    

readAndPrint = \register ->
    byte <- await (readRegister register)
    str = Num.toStr byte
    Stdout.line str

reset = I2c.writeBytes 0 [0x06]

sleep =
    oldMode <- await (readRegister mode1)
    newMode = Num.bitwiseOr oldMode sleepBit
    writeRegister mode1 newMode

wakeup =
    oldMode <- await (readRegister mode1)
    newMode = sleepBit |> bitwiseNot |> Num.bitwiseAnd oldMode
    writeRegister mode1 newMode

bitwiseNot = \bits -> Num.bitwiseXor 0xff bits

