app "high"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Task.{ Task }]
    provides [main] to pf

main : Task {} []
main =
    _ <- Task.await (Stdout.setPinHigh 23)
    Stdout.setPinLow 23

