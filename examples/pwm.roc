app "pwm"
    packages { pf: "../src/main.roc" }
    imports [pf.Gpio, pf.Stdout, pf.Stdin, pf.Task.{ Task }]
    provides [main] to pf

frequency = 50

main : Task {} []
main = Task.forever setPwm

getDutyCycle : Task F64 [InvalidNumStr]
getDutyCycle =
    _            <- Task.await (Stdout.line "Set the duty cycle from 0.0 to 1.0:")
    dutyCycleStr <- Task.await Stdin.line
    Task.fromResult (Str.toF64 dutyCycleStr)

setPwm : Task {} []
setPwm =
    dutyCycleResult <- Task.attempt getDutyCycle
    when dutyCycleResult is
        Ok dutyCycle -> setDutyCycle dutyCycle
        Err InvalidNumStr -> Stdout.line "Duty cycle is invalid. Try again.\n"

setDutyCycle : F64 -> Task {} []
setDutyCycle = \dutyCycle ->
    str = Num.toStr dutyCycle
    result <- Task.attempt (Gpio.pwm frequency dutyCycle)
    when result is
        Ok {}          -> Stdout.line "Duty cycle is: \(str).\n"
        Err PwmFailure -> Stdout.line "Failed to set PWM" 

