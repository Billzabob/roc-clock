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
        Ok dutyCycle ->
            str = Num.toStr dutyCycle
            _ <- Task.await (Stdout.line "Duty cycle is: \(str).\n")
            Gpio.pwm frequency dutyCycle
        _ ->
            Stdout.line "Duty cycle is invalid. Try again.\n"
    

