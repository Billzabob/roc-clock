app "i2c"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.I2c, pf.Task.{ Task }]
    provides [main] to pf

address = 0x0040
# mode1 = 0
# mode2 = 1
# sleepBit = 0x10

main : Task {} []
main =
    _ <- Task.await (readAndPrint 0)
    _ <- Task.await (writeRegister 0 0x01)
    _ <- Task.await (Gpio.sleep 1000)
    _ <- Task.await (readAndPrint 0)
    Task.succeed {}

readRegister = \register ->
    _ <- Task.await (I2c.writeBytes address [register])
    I2c.readBytes address 1

writeRegister = \register, value ->
    I2c.writeBytes address [register, value]
    

readAndPrint = \register ->
    bytes <- Task.await (readRegister register)
    when List.get bytes 0 is
        Ok a ->
            str = Num.toStr a
            Stdout.line str
        Err _ ->
            Stdout.line "Error"

# reset = I2c.writeByte 0 0x06

# sleep =
#     oldMode <- await (readRegister mode1)
#     newMode = Num.bitwiseOr oldMode sleepBit
#     writeRegister mode1 newMode

# wakeup =
#     oldMode <- await (readRegister mode1)
#     newMode = sleepBit |> bitwiseNot |> Num.bitwiseAnd oldMode
#     writeRegister mode1 newMode

# bitwiseNot = \bits -> Num.bitwiseXor 0xFF bits

