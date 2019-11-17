defmodule Lexer do
  import NimbleParsec
  import LexerHelper

  defp chars_to_integer(_, args, context, _, _, base \\ 10) do
    {
      args
      |> Enum.reverse()
      |> to_string()
      |> String.to_integer(base)
      |> List.wrap(),
      context
    }
  end

  sign = ascii_char [?+, ?-]
  digit = ascii_char [?0..?9]
  hexdigit = ascii_char [?0..?9, ?a..?f, ?A..?F]
  num = digit
    |> possible(
      concat(
        optional(ignore(ascii_char([?_]))),
        digit
      )
    ) |> post_traverse(
      {:chars_to_integer, []}
    )
  hexnum = hexdigit
    |> possible(
      concat(
        optional(ignore(ascii_char([?_]))),
        hexdigit
      )
    ) |> post_traverse(
      {:chars_to_integer, [16]}
    )

  letter = ascii_char [?a..?z, ?A..?Z]
  symbol = ascii_char [?+, ?-, ?*, ?/, ?\\, ?^, ?~, ?=, ?<, ?>, ?!, ??, ?@, ?#, ?$, ?%, ?&, ?|, ?:, ?`, ?., ?' ]

  space = ascii_char [?\n, ?\t, ?\r, ?\s ]
  ascii = ascii_char [0x00..0x7f]


  nat = choice([
    concat(string("0x"), hexnum),
    num
  ])

  defparsec :num, num
  defparsec :hexnum, hexnum
  defparsec :nat, nat
end