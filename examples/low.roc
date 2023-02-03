app "low"
    packages { pf: "../src/main.roc" }
    imports [pf.Stdout, pf.Task.{ Task }]
    provides [main] to pf

main : Task {} []
main = Stdout.setPinLow 23

