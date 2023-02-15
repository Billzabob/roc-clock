app "test"
    packages { pf: "../src/main.roc" }
    imports [pf.Pca9685, pf.Task.{ Task }]
    provides [main] to pf

main : Task {} []
main =
    _ <- Task.await (Pca9685.setPinOffTicks 0x0040 1 500)
    _ <- Task.attempt (Pca9685.setPrescale 0x0040 121)
    Task.succeed {}

