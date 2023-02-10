app "i2c"
    packages { pf: "../src/main.roc" }
    imports [pf.I2c, pf.Stdout, pf.Task.{ Task }]
    provides [main] to pf

main : Task {} []
main =
    result <- Task.attempt stuff
    when result is
        Ok a ->
            str = Num.toStr a
            Stdout.line "The register was \(str)"
        Err WriteFailure ->
            Stdout.line "Something failed to write"

stuff =
    _     <- Task.await (I2c.writeByte 0x0040 0x00)
    value <- Task.await (I2c.readByte 0x0040)
    Task.succeed value

