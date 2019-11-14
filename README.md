Wasm deocder and interpreter

(In progress)

example:

```iex
# decode a .wasm file

file = File.read!("priv/program/out/main.wasm")
module =
  Decoder.parse_module(file)
  |> IO.inspect()
```
