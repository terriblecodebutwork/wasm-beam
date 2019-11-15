# mix run script/test_gen.exs

spec_dir =
  "priv/spec/"

specs =
  File.ls!(spec_dir)
  |> Enum.map(fn x -> spec_dir <> x end)

hadnle_result =
  fn
    {:ok, data, _, _, _, _}, spec ->
      File.write("test/#{Path.rootname(spec)}_test.exs", data)
    {:error, msg, _, _, _, _}, spec ->
      {:error, spec, msg}
  end

for spec <- specs do
  File.read!(spec)
  |> Parser.wast()
  |> hadnle_result.(spec)
end