defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  describe "parse wast" do
    test "signle sexp" do
      assert :ok == (
        Parser.wast("""
        ;; front comment
        ("a" "b" "c")
        """)
        |> elem(0)
      )
    end

    test "keyword" do
      source = """
      (module "Abcd"
        (func "efgh")
      )
      """

      assert true == match?(
        {:ok, [
          [:module, "Abcd",
            [:func, "efgh"]
          ]
        ], "", _, _, _},
        Parser.wast(source)
      )
    end

    test "multi sexp" do
      assert :ok == (
        Parser.wast("""
        ;; front comment
        ("a" "b" "c")

        ;; front comment
        ("a" "b" "c")
        """)
        |> elem(0)
      )
    end
  end
end