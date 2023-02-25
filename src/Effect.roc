hosted Effect
    exposes [
        Effect,
        after,
        map,
        always,
        forever,
        loop,
        setPinHigh,
        setPinLow,
        pwm,
        getTime,
        writeBytes,
        readBytes,
        sleep,
        stdoutLine,
        stdoutWrite,
        stderrLine,
        stderrWrite,
        stdinLine,
        sendRequest,
    ]
    imports [InternalHttp.{ Request, Response }]
    generates Effect with [after, map, always, forever, loop]

stdoutLine : Str -> Effect {}
stdoutWrite : Str -> Effect {}
stderrLine : Str -> Effect {}
stderrWrite : Str -> Effect {}
stdinLine : Effect Str

getTime : Effect Str
sleep : U64 -> Effect {}
setPinHigh : U8 -> Effect {}
setPinLow : U8 -> Effect {}
pwm : F64, F64 -> Effect {}

writeBytes : U16, List U8 -> Effect {}
readBytes : U16, Nat -> Effect (List U8)

sendRequest : Box Request -> Effect Response
