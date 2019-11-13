defmodule Number do

  # binary -> {type, integer/float}
  def i32(x) do
    <<x::integer-unsigned-size(32)>> = x
    {:i32, x}
  end

  def i64(x) do
    <<x::integer-unsigned-size(64)>> = x
    {:i64, x}
  end

  def f32(x) do
    <<x::float-unsigned-size(32)>> = x
    {:f32, x}
  end

  def f64(x) do
    <<x::float-unsigned-size(64)>> = x
    {:f64, x}
  end

  # def i32_add({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<y::integer-unsigned-size(32)>>}) do
  #   {:i32, <<(x+y)::integer-unsigned-size(32)>>}
  # end

  # def i32_sub({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<y::integer-unsigned-size(32)>>}) do
  #   {:i32, <<(x-y)::integer-unsigned-size(32)>>}
  # end

  # def i32_mul({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<y::integer-unsigned-size(32)>>}) do
  #   {:i32, <<(x*y)::integer-unsigned-size(32)>>}
  # end

  # def i32_div_u({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<0::integer-unsigned-size(32)>>}) do
  #   :undefined
  # end
  # def i32_div_u({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<y::integer-unsigned-size(32)>>}) do
  #   {:i32, <<div(x, y)::integer-unsigned-size(32)>>}
  # end

  # def i32_div_s({:i32, <<x::integer-signed-size(32)>>}, {:i32, <<0::integer-signed-size(32)>>}) do
  #   :undefined
  # end
  # def i32_div_s({:i32, <<x::integer-signed-size(32)>>}, {:i32, <<y::integer-signed-size(32)>>}) do
  #   r = div(x, y)
  #   if r == trunc(:math.pow(2, 31)) do
  #     :undefined
  #   else
  #     {:i32, <<r::integer-signed-size(32)>>}
  #   end
  # end

  # def i32_rem_u({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<0::integer-unsigned-size(32)>>}) do
  #   :undefined
  # end
  # def i32_rem_u({:i32, <<x::integer-unsigned-size(32)>>}, {:i32, <<y::integer-unsigned-size(32)>>}) do
  #   {:i32, <<rem(x, y)::integer-unsigned-size(32)>>}
  # end

  # def i32_rem_s({:i32, <<x::integer-signed-size(32)>>}, {:i32, <<0::integer-signed-size(32)>>}) do
  #   :undefined
  # end
  # def i32_rem_s({:i32, <<x::integer-signed-size(32)>>}, {:i32, <<y::integer-signed-size(32)>>}) do
  #   {:i32, <<rem(x, y)::integer-signed-size(32)>>}
  # end



  # def testcase do
  #   # i32_add

  #   true =
  #     i32(2) == i32_add(i32(1), i32(1))
  #   true =
  #     i32(0x80000000) == i32_add(i32(0x7fffffff), i32(1))
  #   true =
  #     i32(0) == i32_add(i32(0x80000000), i32(0x80000000))
  # end

end



