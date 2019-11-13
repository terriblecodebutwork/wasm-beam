defmodule LEB128 do
  @moduledoc """
  Little Endian Base 128
  """
  import Bitwise

  def decode_unsigned(bin) do
    {result, rest, size} = decode(bin)
    <<x::unsigned-size(size)>> = result
    {x, rest}
  end

  def decode_signed(bin) do
    {result, rest, size} = decode(bin)
    <<x::signed-size(size)>> = result
    {x, rest}
  end

  @unsigned_max 128
  @signed_max 64

  def encode_unsigned(n) do
    encode(n, 0, <<>>, @unsigned_max)
  end

  def encode_signed(n) do
    encode(n, 0, <<>>, @signed_max)
  end

  defp decode(bin) do
    decode(bin, <<>>, 7)
  end

  defp decode(<<1::size(1), chunk::size(7)-bits, rest::binary>>, result, size) do
    decode(rest, <<chunk::bits, result::bits>>, size + 7)
  end
  defp decode(<<0::size(1), chunk::size(7)-bits, rest::binary>>, result, size) do
    {<<chunk::bits, result::bits>>, rest, size}
  end

  defp encode(n, shift, acc, max) when (n >>> shift) >= -max and (n >>> shift) < max do
    chunk = n >>> shift
    <<acc::bytes, 0::size(1), chunk::size(7)>>
  end
  defp encode(n, shift, acc, max) do
    chunk = n >>> shift
    encode(n, shift + 7, <<acc::bytes, 1::size(1), chunk::size(7)>>, max)
  end
end