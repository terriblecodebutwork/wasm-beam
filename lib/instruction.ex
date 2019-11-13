defmodule Instruction do
  import Bitwise
  @max32 0xFFFFFFFF
  @max64 0xFFFFFFFFFFFFFFFF

  defp mod(:i32, n), do: {:i32, n &&& @max32}
  defp mod(:i64, n), do: {:i64, n &&& @max64}

  def rotr(x, {type, y}) when y < 0, do: rotl(x, {type, -y})
  def rotr({:i32, x}, {:i32, y}) do
    y = rem(y, 32)
    x = :binary.encode_unsigned(x)
    x =
      rroll(x, y, 32)
      |> :binary.decode_unsigned()
    {:i32, x}
  end
  def rotr({:i64, x}, {:i64, y}) do
    y = rem(y, 64)
    x = :binary.encode_unsigned(x)
    x =
      rroll(x, y, 64)
      |> :binary.decode_unsigned()
    {:i64, x}
  end

  def rotl(x, {type, y}) when y < 0, do: rotr(x, {type, -y})
  def rotl({type, x}, {type, y}) do
    rotr({type, x}, {type, 32-y})
  end

  defp rroll(byte, rolls, base) do
    first_size = base - rolls
    <<first::size(first_size), rest::size(rolls)>> = pad_leading(byte, base)
    <<rest::size(rolls), first::size(first_size)>>
  end

  defp pad_leading(bits, n) do
    case n - bit_size(bits) do
      0 ->
        bits
      x ->
        <<0::size(x), bits::bits>>
    end
  end

  def add({type, x}, {type, y}) do
    mod(type, x+y)
  end

  def mul({type, x}, {type, y}) do
    mod(type, x*y)
  end
end