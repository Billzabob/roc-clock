app "servo"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.Stdin, pf.Task.{ Task }]
    provides [main] to pf

frequency = 50

main : Task {} []
main = Task.forever run

getRotationAmount : Task F64 [InvalidNumStr]
getRotationAmount =
    _              <- Task.await (Stdout.line "Set the rotation amount from 0 to 180:")
    rotationAmount <- Task.await Stdin.line
    Task.fromResult (Str.toF64 rotationAmount)

run : Task {} []
run =
    rotationAmountResult <- Task.attempt getRotationAmount
    when rotationAmountResult is
        Ok rotationAmount -> setRotation rotationAmount
        Err InvalidNumStr -> Stdout.line "Duty cycle is invalid. Try again.\n"

setRotation : F64 -> Task {} []
setRotation = \rotationAmount ->
    dutyCycle = map rotationAmount 0 180 0.035 0.12
    str = Num.toStr dutyCycle
    result <- Task.attempt (Gpio.pwm frequency dutyCycle)
    when result is
        Ok {} -> Stdout.line "Duty cycle is: \(str).\n"
        Err PwmFailure -> Stdout.line "Failed to set PWM"

map = \value, inMin, inMax, outMin, outMax -> (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin

