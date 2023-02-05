app "blink"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Task.{ Task }]
    provides [main] to pf

pin = 31

main : Task {} []
main = Task.forever blink

blink : Task {} []
blink =
    _ <- Task.attempt (Gpio.setPinHigh pin)
    _ <- Task.await (Gpio.sleep 1000)
    _ <- Task.attempt (Gpio.setPinLow pin)
    _ <- Task.await (Gpio.sleep 1000)
    Task.succeed {}

