defmodule InstructionTest do
  use ExUnit.Case
  doctest Instruction

  describe "i64" do

  end

  describe "i32" do
    test "i32.add" do
      assert {:i32, 2} == Instruction.add {:i32, 1}, {:i32, 1}
      assert {:i32, 0} == Instruction.add {:i32, 0x80000000}, {:i32, 0x80000000}
    end

    test "i32.mul" do
      assert {:i32, 1} == Instruction.mul {:i32, 1}, {:i32, 1}
      assert {:i32, 0x358e7470} == Instruction.mul {:i32, 0x01234567}, {:i32, 0x76543210}
    end

    test "i32.rotr" do
      assert {:i32, 0x80000000} == Instruction.rotr {:i32, 1}, {:i32, 1}
      assert {:i32, 1} == Instruction.rotr {:i32, 1}, {:i32, 0}
      # assert {:i32, -1} == Instruction.rotr {:i32, -1}, {:i32, 1}
      assert {:i32, 1} == Instruction.rotr {:i32, 1}, {:i32, 32}
      assert {:i32, 0x7f806600} == Instruction.rotr {:i32, 0xff00cc00}, {:i32, 1}
      assert {:i32, 0x00008000} == Instruction.rotr {:i32, 0x00080000}, {:i32, 4}
      assert {:i32, 0x1d860e97} == Instruction.rotr {:i32, 0xb0c1d2e3}, {:i32, 5}
    end

    test "i32.rotl" do
      assert Instruction.rotl({:i32, 1}, {:i32, 1}) == {:i32, 2}
      assert Instruction.rotl({:i32, 1}, {:i32, 0}) == {:i32, 1}
      # assert Instruction.rotl({:i32, -1}, {:i32, 1}) == {:i32, -1}
      assert Instruction.rotl({:i32, 1}, {:i32, 32}) == {:i32, 1}
      assert Instruction.rotl({:i32, 0xabcd9876}, {:i32, 1}) == {:i32,  0x579b30ed}
      assert Instruction.rotl({:i32, 0xfe00dc00}, {:i32, 4}) == {:i32, 0xe00dc00f}
      assert Instruction.rotl({:i32, 0xb0c1d2e3}, {:i32, 5}) == {:i32, 0x183a5c76}
      assert Instruction.rotl({:i32, 0x00008000}, {:i32, 37}) == {:i32, 0x00100000}
      # assert Instruction.rotl({:i32, 0xb0c1d2e3}, {:i32, 0xff05}) == {:i32, 0x183a5c76}
      assert Instruction.rotl({:i32, 0x769abcdf}, {:i32, 0xffffffed}) == {:i32, 0x579beed3}
      assert Instruction.rotl({:i32, 0x769abcdf}, {:i32, 0x8000000d}) == {:i32, 0x579beed3}
      assert Instruction.rotl({:i32, 1}, {:i32, 31}) == {:i32, 0x80000000}
      assert Instruction.rotl({:i32, 0x80000000}, {:i32, 1}) == {:i32, 1}
    end
  end
end