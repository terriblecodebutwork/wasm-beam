defmodule Decoder do
  import Bitwise
  import LEB128, only: [decode_unsigned: 1, decode_signed: 1]

  def parse_module(<<0, "asm", stream::binary>>) do
    parse_section(stream, %{})
  end

  def parse_code(stream) do
    {locals, stream} = parse_vector(stream, &parse_locals/1)
    {instructions, stream} = parse_instructions(stream)
    { {:code, locals, instructions}, stream}
  end

  def parse_locals(stream) do
    {n, stream} = parse_unsigned(stream)
    {result, stream} = Enum.reduce(1..n, {[], stream}, fn _, {r, s} ->
      {t, s} = next(s)
      {[typemap(t)|r], s}
    end)
    {Enum.reverse(result), stream}
  end

  def parse_instructions(stream), do: parse_instructions(stream, [])

  def parse_instructions(<<0x0b::size(8), stream::binary>>, instructions) do
    { Enum.reverse(instructions), stream}
  end
  def parse_instructions(<<op::size(8), stream::binary>>, instructions) do
    {name, funcs} = opcode(op)
    {result, stream} = Enum.reduce(funcs, {[], stream}, fn f, {r, s} ->
      {t, s} = f.(s)
      {[t|r], s}
    end)
    parse_instructions(stream, [[name | Enum.reverse(result)]|instructions] )
  end

  # {:global, globaltype, expr}
  def parse_global(stream) do
    {gtp, stream} = parse_globaltype(stream)
    {ins, stream} = parse_instructions(stream)
    { {:global, gtp, ins}, stream }
  end

  # {:global_type, type, mut}
  def parse_globaltype(<<t::size(8), m::size(8), stream::bytes>>) do
    { {:global_type, typemap(t), m}, stream }
  end

  def parse_typemap(stream) do
    {x, stream} = next(stream)
    {typemap(x), stream}
  end

  def opcode(op) do
    case op do
      0x00 ->
        {:unreachable, []}
      0x01 ->
        {:nop, []}
      0x02 ->
        {:block, [&parse_typemap/1, &parse_instructions/1]}
      0x03 ->
        {:loop, [&parse_typemap/1, &parse_instructions/1]}
      0x04 ->
        {:if, [&parse_typemap/1, fn stream ->
          {instructions, stream} = parse_instructions(stream)
          {split_else(instructions), stream}
        end]}
      0x05 ->
        {:else, []}
      0x0c ->
        {:br, [&parse_unsigned/1]}
      0x0d ->
        {:br_if, [&parse_unsigned/1]}
      0x0e ->
        {:br_table, [fn s -> parse_vector(s, &parse_unsigned/1) end, &parse_unsigned/1]}
      0x0f ->
        {:return, []}
      0x10 ->
        {:call, [&parse_unsigned/1]}
      0x11 ->
        {:call_indirect, [&parse_unsigned/1, &next/1]}
      0x1a ->
        {:drop, []}
      0x1b ->
        {:select, []}
      0x20 ->
        {:local_get, [&parse_unsigned/1]}
      0x21 ->
        {:local_set, [&parse_unsigned/1]}
      0x22 ->
        {:local_tee, [&parse_unsigned/1]}
      0x23 ->
        {:global_get, [&parse_unsigned/1]}
      0x24 ->
        {:global_set, [&parse_unsigned/1]}
      0x28 ->
        {:i32_load, [&parse_signed/1, &parse_signed/1]}
      0x29 ->
        {:i64_load, [&parse_signed/1, &parse_signed/1]}
      0x2a ->
        {:f32_load, [&parse_signed/1, &parse_signed/1]}
      0x2b ->
        {:f64_load, [&parse_signed/1, &parse_signed/1]}
      0x2c ->
        {:i32_load8_s, [&parse_signed/1, &parse_signed/1]}
      0x2d ->
        {:i32_load8_u, [&parse_signed/1, &parse_signed/1]}
      0x2e ->
        {:i32_load16_s, [&parse_signed/1, &parse_signed/1]}
      0x2f ->
        {:i32_load16_u, [&parse_signed/1, &parse_signed/1]}
      0x30 ->
        {:i64_load8_s, [&parse_signed/1, &parse_signed/1]}
      0x31 ->
        {:i64_load8_u, [&parse_signed/1, &parse_signed/1]}
      0x32 ->
        {:i64_load16_s, [&parse_signed/1, &parse_signed/1]}
      0x33 ->
        {:i64_load16_u, [&parse_signed/1, &parse_signed/1]}
      0x34 ->
        {:i64_load32_s, [&parse_signed/1, &parse_signed/1]}
      0x35 ->
        {:i64_load32_u, [&parse_signed/1, &parse_signed/1]}
      0x36 ->
        {:i32_store, [&parse_signed/1, &parse_signed/1]}
      0x37 ->
        {:i64_store, [&parse_signed/1, &parse_signed/1]}
      0x38 ->
        {:f32_store, [&parse_signed/1, &parse_signed/1]}
      0x39 ->
        {:f64_store, [&parse_signed/1, &parse_signed/1]}
      0x3a ->
        {:i32_store8, [&parse_signed/1, &parse_signed/1]}
      0x3b ->
        {:i32_store16, [&parse_signed/1, &parse_signed/1]}
      0x3c ->
        {:i64_store8, [&parse_signed/1, &parse_signed/1]}
      0x3d ->
        {:i64_store16, [&parse_signed/1, &parse_signed/1]}
      0x3e ->
        {:i64_store32, [&parse_signed/1, &parse_signed/1]}
      0x3f ->
        {:memory_size, [&next/1]}
      0x40 ->
        {:memory_grow, [&next/1]}
      0x41 ->
        {:i32_const, [&parse_signed/1]}
      0x42 ->
        {:i64_const, [&parse_signed/1]}
      0x43 ->
        {:f32_const, [&parse_float32/1]}
      0x44 ->
        {:f64_const, [&parse_float64/1]}
      0x45 ->
        {:i32_eqz, []}
      0x46 ->
        {:i32_eq, []}
      0x47 ->
        {:i32_ne, []}
      0x48 ->
        {:i32_lt_s, []}
      0x49 ->
        {:i32_lt_u, []}
      0x4a ->
        {:i32_gt_s, []}
      0x4b ->
        {:i32_gt_u, []}
      0x4c ->
        {:i32_le_s, []}
      0x4d ->
        {:i32_le_u, []}
      0x4e ->
        {:i32_ge_s, []}
      0x4f ->
        {:i32_ge_u, []}
      0x50 ->
        {:i64_eqz, []}
      0x51 ->
        {:i64_eq, []}
      0x52 ->
        {:i64_ne, []}
      0x53 ->
        {:i64_lt_s, []}
      0x54 ->
        {:i64_lt_u, []}
      0x55 ->
        {:i64_gt_s, []}
      0x56 ->
        {:i64_gt_u, []}
      0x57 ->
        {:i64_le_s, []}
      0x58 ->
        {:i64_le_u, []}
      0x59 ->
        {:i64_ge_s, []}
      0x5a ->
        {:i64_ge_u, []}
      0x5b ->
        {:f32_eq, []}
      0x5c ->
        {:f32_ne, []}
      0x5d ->
        {:f32_lt, []}
      0x5e ->
        {:f32_gt, []}
      0x5f ->
        {:f32_le, []}
      0x60 ->
        {:f32_ge, []}
      0x61 ->
        {:f64_eq, []}
      0x62 ->
        {:f64_ne, []}
      0x63 ->
        {:f64_lt, []}
      0x64 ->
        {:f64_gt, []}
      0x65 ->
        {:f64_le, []}
      0x66 ->
        {:f64_ge, []}
      0x67 ->
        {:i32_clz, []}
      0x68 ->
        {:i32_ctz, []}
      0x69 ->
        {:i32_popcnt, []}
      0x6a ->
        {:i32_add, []}
      0x6b ->
        {:i32_sub, []}
      0x6c ->
        {:i32_mul, []}
      0x6d ->
        {:i32_div_s, []}
      0x6e ->
        {:i32_div_u, []}
      0x6f ->
        {:i32_rem_s, []}
      0x70 ->
        {:i32_rem_u, []}
      0x71 ->
        {:i32_and, []}
      0x72 ->
        {:i32_or, []}
      0x73 ->
        {:i32_xor, []}
      0x74 ->
        {:i32_shl, []}
      0x75 ->
        {:i32_shr_s, []}
      0x76 ->
        {:i32_shr_u, []}
      0x77 ->
        {:i32_rotl, []}
      0x78 ->
        {:i32_rotr, []}
      0x79 ->
        {:i64_clz, []}
      0x7a ->
        {:i64_ctz, []}
      0x7b ->
        {:i64_popcnt, []}
      0x7c ->
        {:i64_add, []}
      0x7d ->
        {:i64_sub, []}
      0x7e ->
        {:i64_mul, []}
      0x7f ->
        {:i64_div_s, []}
      0x80 ->
        {:i64_div_u, []}
      0x81 ->
        {:i64_rem_s, []}
      0x82 ->
        {:i64_rem_u, []}
      0x83 ->
        {:i64_and, []}
      0x84 ->
        {:i64_or, []}
      0x85 ->
        {:i64_xor, []}
      0x86 ->
        {:i64_shl, []}
      0x87 ->
        {:i64_shr_s, []}
      0x88 ->
        {:i64_shr_u, []}
      0x89 ->
        {:i64_rotl, []}
      0x8a ->
        {:i64_rotr, []}
      0x8b ->
        {:f32_abs, []}
      0x8c ->
        {:f32_neg, []}
      0x8d ->
        {:f32_ceil, []}
      0x8e ->
        {:f32_floor, []}
      0x8f ->
        {:f32_trunc, []}
      0x90 ->
        {:f32_nearest, []}
      0x91 ->
        {:f32_sqrt, []}
      0x92 ->
        {:f32_add, []}
      0x93 ->
        {:f32_sub, []}
      0x94 ->
        {:f32_mul, []}
      0x95 ->
        {:f32_div, []}
      0x96 ->
        {:f32_min, []}
      0x97 ->
        {:f32_max, []}
      0x98 ->
        {:f32_copysign, []}
      0x99 ->
        {:f64_abs, []}
      0x9a ->
        {:f64_neg, []}
      0x9b ->
        {:f64_ceil, []}
      0x9c ->
        {:f64_floor, []}
      0x9d ->
        {:f64_trunc, []}
      0x9e ->
        {:f64_nearest, []}
      0x9f ->
        {:f64_sqrt, []}
      0xa0 ->
        {:f64_add, []}
      0xa1 ->
        {:f64_sub, []}
      0xa2 ->
        {:f64_mul, []}
      0xa3 ->
        {:f64_div, []}
      0xa4 ->
        {:f64_min, []}
      0xa5 ->
        {:f64_max, []}
      0xa6 ->
        {:f64_copysign, []}
      0xa7 ->
        {:i32_wrap_i64, []}
      0xa8 ->
        {:i32_trunc_f32_s, []}
      0xa9 ->
        {:i32_trunc_f32_u, []}
      0xaa ->
        {:i32_trunc_f64_s, []}
      0xab ->
        {:i32_trunc_f64_u, []}
      0xac ->
        {:i64_extend_i32_s, []}
      0xad ->
        {:i64_extend_i32_u, []}
      0xae ->
        {:i64_trunc_f32_s, []}
      0xaf ->
        {:i64_trunc_f32_u, []}
      0xb0 ->
        {:i64_trunc_f64_s, []}
      0xb1 ->
        {:i64_trunc_f64_u, []}
      0xb2 ->
        {:f32_convert_i32_s, []}
      0xb3 ->
        {:f32_convert_i32_u, []}
      0xb4 ->
        {:f32_convert_i64_s, []}
      0xb5 ->
        {:f32_convert_i64_u, []}
      0xb6 ->
        {:f32_demote_f64, []}
      0xb7 ->
        {:f64_convert_i32_s, []}
      0xb8 ->
        {:f64_convert_i32_u, []}
      0xb9 ->
        {:f64_convert_i64_s, []}
      0xba ->
        {:f64_convert_i64_u, []}
      0xbb ->
        {:f64_promote_f32, []}
      0xbc ->
        {:i32_reinterpret_f32, []}
      0xbd ->
        {:i64_reinterpret_f64, []}
      0xbe ->
        {:f32_reinterpret_i32, []}
      0xbf ->
        {:f64_reinterpret_i64, []}
    end
  end

  defp split_else(ins), do: split_else(ins, [])

  defp split_else([:else|t], result) do
    [Enum.reverse(result), t]
  end
  defp split_else([h|t], result) do
    split_else(t, [h|result])
  end
  defp split_else([], result) do
    [Enum.reverse(result), []]
  end

  def next(<<x::size(8), stream::binary>>) do
    {x, stream}
  end

  def bslice(<<x::size(8), stream::binary>>) do
    islice(stream, x)
  end

  defp islice(stream, n) do
    <<x::size(n)-bytes, stream::binary>> = stream
    {x, stream}
  end

  defp typemap(0x7f), do: :i32
  defp typemap(0x7e), do: :i64
  defp typemap(0x7d), do: :f32
  defp typemap(0x7c), do: :f64
  defp typemap(0x70), do: :anyfunc
  defp typemap(0x60), do: :func
  defp typemap(0x40), do: nil

  defp section(1), do: {:type, fn s -> parse_vector(s, &parse_functype/1) end}
  # defp section(2), do: {:import, &bslice/1}
  defp section(3), do: {:func, fn s -> parse_vector(s, &parse_unsigned/1) end}
  # defp section(4), do: {:table, &bslice/1}
  defp section(5), do: {:memory, fn s -> parse_vector(s, &parse_limits/1) end}
  defp section(6), do: {:global, fn s -> parse_vector(s, &parse_global/1) end}
  defp section(7), do: {:export, fn s -> parse_vector(s, &parse_export/1) end}
  # defp section(8), do: {:start, &bslice/1}
  # defp section(9), do: {:element, &bslice/1}
  defp section(10), do: {:code, fn s -> parse_vector(s, &parse_rawcode/1) end}
  # defp section(11), do: {:data, &bslice/1}
  defp section(_), do: :custom

  # {:limits, min, max}
  def parse_limits(<<0x00, stream::bytes>>) do
    {min, stream} = parse_unsigned(stream)
    { {:limits, min, nil}, stream }
  end
  def parse_limits(<<0x01, stream::bytes>>) do
    {min, stream} = parse_unsigned(stream)
    {max, stream} = parse_unsigned(stream)
    { {:limits, min, max}, stream }
  end

  def parse_section(<<>>, sections), do: sections
  def parse_section(<<sectnum::unsigned-integer-size(8), stream::binary>>, sections) do
    {size, stream} = parse_unsigned(stream)
    {stream, sections} =
      if size > 0 do
        {sectname, item, stream} =
          case section(sectnum) do
            {sectname, func} ->
              {item, stream} = func.(stream)
              {sectname, item, stream}
            :custom ->
              {item, stream} = islice(stream, size)
              {:custom, item, stream}
          end
        {stream, Map.put(sections, sectname, item)}
      else
        {stream, sections}
      end
    parse_section(stream, sections)
  end

  def parse_vector(stream, func) do
    {n, stream} = parse_unsigned(stream)
    parse_vector(stream, func, [], n)
  end

  def parse_vector(stream, _, result, 0) do
    {Enum.reverse(result), stream}
  end
  def parse_vector(stream, func, result, n) do
    {x, stream} = func.(stream)
    parse_vector(stream, func, [x|result], n-1)
  end

  def parse_functype(<<sigtype::size(8), stream::binary>>) do
    {params, stream} = parse_vector(stream, &parse_typemap/1)
    {returns, stream} = parse_vector(stream, &parse_typemap/1)
    {{:function_type, params, returns}, stream}
  end

  defp parse_string(stream) do
    {bytes, stream} = parse_vector(stream, &next/1)
    {IO.iodata_to_binary(bytes), stream}
  end

  # {_, name, ref}
  defp exports(0), do: :export_function
  defp exports(1), do: :export_table
  defp exports(2), do: :export_memory
  defp exports(3), do: :export_global

  defp parse_export(stream) do
    {name, <<x::size(8), stream::binary>>} = parse_string(stream)
    {ref, stream} = parse_unsigned(stream)
    { {exports(x), name, ref}, stream}
  end

  defp parse_rawcode(stream) do
    {size, stream} = parse_unsigned(stream)
    islice(stream, size)
  end

  def parse_unsigned(stream), do: decode_unsigned(stream)
  def parse_signed(stream), do: decode_signed(stream)

  def parse_float64(<<x::float-size(64)-little, stream::bytes>>) do
    {x, stream}
  end

  def parse_float32(<<x::float-size(32)-little, stream::bytes>>) do
    {x, stream}
  end

end

# file = File.read!("/Users/zlj/elixir/my_app/priv/program/out/main.wasm")
file = File.read! "/Users/zlj/python/wadze/input.wasm"
module =
  Decoder.parse_module(file)
  |> IO.inspect()

for code <- module.code do
  Decoder.parse_code(code)
  |> IO.inspect()
end