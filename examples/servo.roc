app "servo"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.Stdin, pf.Task.{ Task }]
    provides [main] to pf

frequency = 50

main : Task {} []
main = Task.forever setRotation

getRotationAmount : Task F64 [InvalidNumStr]
getRotationAmount = 
    _            <- Task.await (Stdout.line "Set the rotation amount from 0 to 180:")
    rotationAmount <- Task.await Stdin.line
    Task.fromResult (Str.toF64 rotationAmount)

setRotation : Task {} []
setRotation =
    rotationAmountResult <- Task.attempt getRotationAmount
    when rotationAmountResult is
        Ok rotationAmount ->
            dutyCycle = map rotationAmount 0 180 0.05 0.1
            str = Num.toStr dutyCycle
            result <- Task.attempt (Gpio.pwm frequency dutyCycle)
            when result is
                Ok {} -> Stdout.line "Duty cycle is: \(str).\n"
                Err PwmFailure -> Stdout.line "Failed to set PWM"
        Err InvalidNumStr ->
            Stdout.line "Duty cycle is invalid. Try again.\n"

map = \value, inMin, inMax, outMin, outMax -> (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin

