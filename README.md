# pi-gpio-platform

A Roc platform for Raspberry Pi GPIO

## Examples

See the examples directory for all examples

### Blink LED
```coffee
app "blink"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Task.{ Task }]
    provides [main] to pf

pin = 18

main = Task.forever blink

blink =
    _ <- Task.await (Gpio.setPinHigh pin)
    _ <- Task.await (Task.sleep 1000)
    _ <- Task.await (Gpio.setPinLow pin)
    _ <- Task.await (Task.sleep 1000)
    Task.succeed {}
```
