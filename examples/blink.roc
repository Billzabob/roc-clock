app "blink"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Task.{ Task }]
    provides [main] to pf

pin = 18

main : Task {} []
main = Task.forever blink

blink : Task {} []
blink =
    _ <- Task.await (Gpio.setPinHigh pin)
    _ <- Task.await (Task.sleep 1000)
    _ <- Task.await (Gpio.setPinLow pin)
    _ <- Task.await (Task.sleep 1000)
    Task.succeed {}

