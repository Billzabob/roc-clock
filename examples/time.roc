app "time"
    packages { pf: "../src/main.roc" }
    imports [pf.Http, pf.Task.{ Task, await }, pf.Stdout]
    provides [main] to pf

main : Task {} []
main =
    _ <- Task.attempt foo
    Task.succeed {}

foo =
    a <- await getTime
    _ <- await (Stdout.line a.hour)
    _ <- await (Stdout.line a.minute)
    _ <- await (a.second |> Num.toStr |> Stdout.line)
    Task.succeed {}

getTime =
    resp <- await (Http.send request)
    resp
    |> Str.split "\n"
    |> List.findFirst \row -> (row |> Str.startsWith "datetime")
    |> Result.try (\s -> s |> Str.split "T" |> List.get 1)
    |> Result.try (\s -> s |> Str.split "-" |> List.get 0)
    |> Result.try (\s -> s |> Str.split "-" |> List.get 0)
    |> Result.try parseTime
    |> Task.fromResult

# Could be much cleaner with a parser but this works
parseTime = \str ->
    when Str.split str "." is
        [time, _frac] ->
            when Str.split time ":" is
                [hour, minute, s] ->
                    when Str.toU8 s is
                        Ok second -> Ok { hour, minute, second }
                        _ -> Err TimeParseError
                _ -> Err TimeParseError
        _ -> Err TimeParseError

request = {
    method: Get,
    headers: [],
    url: "http://worldtimeapi.org/api/timezone/America/Denver.txt",
    body: Http.emptyBody,
    timeout: NoTimeout,
}
