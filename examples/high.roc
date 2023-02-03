app "high"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Stdin, pf.Task.{ Task }]
    provides [main] to pf

main : Task {} []
main =
    _ <- Task.attempt (Stdout.setPinHigh 23)
    _ <- Task.await Stdin.line
    _ <- Task.attempt (Stdout.setPinLow 23)
    Task.succeed {}

