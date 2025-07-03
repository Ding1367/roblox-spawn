# roblox-spawn
An alternative to promises that is (mostly) faster.

## How do I use it?
Obviously start by requiring spawn. Because spawn is deprecated you could store the result in local spawn.

### Wait... how do I get spawn???
Just copy the contents of the spawn.lua file in the repository, and paste it wherever you want in a ModuleScript preferably named "spawn."

```luau
-- In this case it is in ReplicatedStorage
local spawn = require(game.ReplicatedStorage.spawn)
```
Requiring `spawn` does not return a table, it returns a function. If you do not prefer this, the implementation is pretty short so you could just change it yourself.
To actually spawn a task, called a Summon, you call it with a function and some parameters. This is the definition of spawn:
```luau
spawn: (func: (any...) -> (any...), ...) -> Summon
```

So to spawn a task you would call it like so:
```luau
local summon = spawn(function(a, b)
    print(`Hello from spawn! {a} + {b} = {a + b}`)
    return a * b
end, 5, 12)
```

Notice that the function returns `a` multipled by `b`. To get/use this value you can use the `Summon:join()` function or the `Summon:thenDo(func: (...any) -> (...any))` function.

### What is Summon:join() though???
Summon:join() returns whether the Summon completed execution (without faulting or timing out) and the return value (or the error message).
If the Summon did NOT complete, you can differentiate between halted and error'd via `Summon.halted` and if there was an error the second return value will be the error message.
If you didn't make the connection, `spawn(func, ...):join()` is a **glorified pcall**, and you should use pcall if your use is that simple.

Here's a chunk of code that covers all chaining functions (that aren't variations of another one):
```luau
spawn(function(a)
    print(a .. " is my favorite number")
    return a * a
end, {} --[[ clearly not a number]])
    :thenDo(print) --[[ print a^2 ]]
    :ifError(warn) --[[ simple error handling ]]
    :alwaysDo(print, "This code should error") --[[ this will always run ]]
    :join() --[[ wait up ]]
```

A bit to unpack. So let's start with ifError, `ifError` takes in a function and is called with the error message.
`alwaysDo` will always call the input function and the other parameters. In other words, alwaysDo is akin to `Promise:andThenCall` except it will always run.

### The variants I was talking about
`Summon:thenCall(func, ...)` is literally Promise:andThenCall where it takes a function, the parameters to pass into the function, and will call the function with the parameters if successful.
`Summon:ifErrorCall(func, ...)` is the same thing except for only when the code errors.

### Two more functions to unpack
`Summon:halt()` will halt the execution of the Summon.
`Summon:timeout(duration)` will, in `duration` seconds, time out the Summon if it has not returned.

That is literally the entire "library." There's more code in example.lua that you can look at if you'd like.
