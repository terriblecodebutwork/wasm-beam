defmodule LEB128Test do
  use ExUnit.Case
  doctest LEB128

  describe "decoding" do
    test "decode unsigned" do
      assert {1, <<>>} == LEB128.decode_unsigned <<1>>
      assert {127, <<>>} == LEB128.decode_unsigned <<127>>
      assert {128, <<>>} == LEB128.decode_unsigned <<128, 1>>
      assert {256, <<>>} == LEB128.decode_unsigned <<128, 2>>
      assert {512, <<>>} == LEB128.decode_unsigned <<128, 4>>
      assert {624485, <<>>} == LEB128.decode_unsigned <<0xe5, 0x8e, 0x26>>
      assert {624485, <<0x01>>} == LEB128.decode_unsigned <<0xe5, 0x8e, 0x26, 0x01>>
      assert {624485, <<0xa4>>} == LEB128.decode_unsigned <<0xe5, 0x8e, 0x26, 0xa4>>
    end

    test "decode signed" do
      assert {-1, <<>>} == LEB128.decode_signed <<127>>
      assert {-127, <<>>} == LEB128.decode_signed <<129, 127>>
      assert {-128, <<>>} == LEB128.decode_signed <<128, 127>>
      assert {-256, <<>>} == LEB128.decode_signed <<128, 126>>
      assert {-512, <<>>} == LEB128.decode_signed <<128, 124>>
      assert {-624485, <<>>} == LEB128.decode_signed <<0x9b, 0xf1, 0x59>>
      assert {-624485, <<0x01>>} == LEB128.decode_signed <<0x9b, 0xf1, 0x59, 0x01>>
      assert {-624485, <<0xa4>>} == LEB128.decode_signed <<0x9b, 0xf1, 0x59, 0xa4>>
    end
  end

  describe "encoding" do
    test "encode unsigned" do
      assert <<1>> == LEB128.encode_unsigned 1
      assert <<127>> == LEB128.encode_unsigned 127
      assert <<128, 1>> == LEB128.encode_unsigned 128
      assert <<128, 2>> == LEB128.encode_unsigned 256
      assert <<128, 4>> == LEB128.encode_unsigned 512
      assert <<0xe5, 0x8e, 0x26>> == LEB128.encode_unsigned 624485
    end

    test "encode signed" do
      assert <<127>> == LEB128.encode_signed -1
      assert <<129, 127>> == LEB128.encode_signed -127
      assert <<128, 127>> == LEB128.encode_signed -128
      assert <<128, 126>> == LEB128.encode_signed -256
      assert <<128, 124>> == LEB128.encode_signed -512
      assert <<0x9b, 0xf1, 0x59>> == LEB128.encode_signed -624485
    end
  end
end