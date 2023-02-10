app "i2c"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.I2c, pf.Task.{ Task, await }]
    provides [main] to pf

address = 0x0040
mode1 = 0
# mode2 = 1
sleepBit = 0x10

main : Task {} []
main =
    result <- Task.attempt run
    when result is
        Ok _ -> Stdout.line "Success"
        Err _ -> Stdout.line "Success"

run =
    _ <- await (readAndPrint mode1)
    _ <- await (reset)
    _ <- await (Gpio.sleep 1000)
    _ <- await (readAndPrint mode1)
    _ <- await (wakeup)
    _ <- await (Gpio.sleep 1000)
    _ <- await (readAndPrint mode1)
    _ <- await (sleep)
    _ <- await (Gpio.sleep 1000)
    _ <- await (readAndPrint mode1)
    Task.succeed {}

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

bitwiseNot = \bits -> Num.bitwiseXor 0xFF bits

