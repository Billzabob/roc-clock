interface Time
    exposes [getTime]
    imports [Effect, Task.{ Task }, InternalTask]

getTime : Task Str *
getTime =
    Effect.getTime
    |> Effect.map Ok
    |> InternalTask.fromEffect
