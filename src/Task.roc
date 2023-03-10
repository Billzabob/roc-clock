interface Task
    exposes [Task, sleep, succeed, fail, await, map, mapFail, onFail, attempt, forever, loop, fromResult, traverse, map2]
    imports [Effect, InternalTask]

Task ok err : InternalTask.Task ok err

forever : Task val err -> Task * err
forever = \task ->
    looper = \{} ->
        task
        |> InternalTask.toEffect
        |> Effect.map
            \res ->
                when res is
                    Ok _ -> Step {}
                    Err e -> Done (Err e)

    Effect.loop {} looper
    |> InternalTask.fromEffect

loop : state, (state -> Task [Step state, Done done] err) -> Task done err
loop = \state, step ->
    looper = \current ->
        step current
        |> InternalTask.toEffect
        |> Effect.map
            \res ->
                when res is
                    Ok (Step newState) -> Step newState
                    Ok (Done result) -> Done (Ok result)
                    Err e -> Done (Err e)

    Effect.loop state looper
    |> InternalTask.fromEffect

sleep : U64 -> Task {} *
sleep = \duration ->
    Effect.sleep duration
    |> Effect.map (\_ -> Ok {})
    |> InternalTask.fromEffect

succeed : ok -> Task ok *
succeed = \ok -> InternalTask.succeed ok

fail : err -> Task * err
fail = \err -> InternalTask.fail err

attempt : Task a b, (Result a b -> Task c d) -> Task c d
attempt = \task, transform ->
    effect = Effect.after
        (InternalTask.toEffect task)
        \result ->
            when result is
                Ok ok -> transform (Ok ok) |> InternalTask.toEffect
                Err err -> transform (Err err) |> InternalTask.toEffect

    InternalTask.fromEffect effect

await : Task a err, (a -> Task b err) -> Task b err
await = \task, transform ->
    effect = Effect.after
        (InternalTask.toEffect task)
        \result ->
            when result is
                Ok a -> transform a |> InternalTask.toEffect
                Err err -> Task.fail err |> InternalTask.toEffect

    InternalTask.fromEffect effect

onFail : Task ok a, (a -> Task ok b) -> Task ok b
onFail = \task, transform ->
    effect = Effect.after
        (InternalTask.toEffect task)
        \result ->
            when result is
                Ok a -> Task.succeed a |> InternalTask.toEffect
                Err err -> transform err |> InternalTask.toEffect

    InternalTask.fromEffect effect

map : Task a err, (a -> b) -> Task b err
map = \task, transform ->
    effect = Effect.after
        (InternalTask.toEffect task)
        \result ->
            when result is
                Ok ok -> Task.succeed (transform ok) |> InternalTask.toEffect
                Err err -> Task.fail err |> InternalTask.toEffect

    InternalTask.fromEffect effect

mapFail : Task ok a, (a -> b) -> Task ok b
mapFail = \task, transform ->
    effect = Effect.after
        (InternalTask.toEffect task)
        \result ->
            when result is
                Ok ok -> Task.succeed ok |> InternalTask.toEffect
                Err err -> Task.fail (transform err) |> InternalTask.toEffect

    InternalTask.fromEffect effect

## Use a Result among other Tasks by converting it into a Task.
fromResult : Result ok err -> Task ok err
fromResult = \result ->
    when result is
        Ok ok -> succeed ok
        Err err -> fail err

traverse : List a, (a -> Task b err) -> Task (List b) err
traverse = \list, f ->
    initialState = list |> List.len |> List.withCapacity |> Task.succeed
    walker = \task, elem -> map2 task (f elem) List.append
    List.walk list initialState walker

map2 : Task a err, Task b err, (a, b -> c) -> Task c err
map2 = \task1, task2, f ->
    a <- await task1
    b <- await task2
    Task.succeed (f a b)
