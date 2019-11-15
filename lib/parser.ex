defmodule Parser do
  import NimbleParsec

  left =
    ascii_char [?(]

  right =
    ascii_char [?)]

  quota =
    ascii_char [?"]

  stringelem =
    utf8_string([not: ?"], min: 1)

  string =
    ignore(quota)
    |> choice([
      concat(repeat(stringelem), ignore(quota)),
      ignore(quota)
    ])


  idchar =
    ascii_char([
      ?0..?9, ?a..?z, ?A..?Z,
      ?!, ?#, ?$, ?%, ?&, ?', ?*, ?+, ?-, ?., ?/, ?:, ?<, ?=, ?>, ??, ?@, ?\\, ?^, ?_, ?`, ?|, ?~
    ])

  defp char_to_atom(_rest, args, context, _line, _offset) do
    {
      args
      |> Enum.reverse()
      |> to_string()
      |> String.to_atom()
      |> List.wrap(),
      context
    }
  end

  keyword =
    concat(
      ascii_char([?a..?z]),
      repeat(idchar)
    )
    |> post_traverse({:char_to_atom, []})

  # defparsec :keyword, keyword

  token =
    choice([
      keyword,
      string
    ])

  elems =
    repeat(
      token
      |> optional(
        ignore(string(" "))
      )
    )

  comment =
      ignore(string(";;"))
      |> optional(
        utf8_string([not: ?\n], min: 1)
      )
      |> ignore(string("\n"))

  whitespace =
      repeat(
        choice([
          string(" "),
          string("\n"),
          string("\t"),
          string("\r")
        ])
      )

  defparsec :wast,
            optional(ignore(comment))
            |> optional(ignore(whitespace))
            |> ignore(left)
            |> repeat(lookahead_not(right) |> choice([parsec(:wast), elems]))
            |> ignore(right)
            |> optional(ignore(whitespace))
            |> wrap()
            |> repeat(lookahead_not(eos()) |> parsec(:wast))

  # opening_tag =
  #   ignore(string("<"))
  #   |> concat(tag)
  #   |> ignore(string(">"))

  # closing_tag =
  #   ignore(string("</"))
  #   |> concat(tag)
  #   |> ignore(string(">"))

  # defparsec :xml,
  #           opening_tag
  #           |> repeat(lookahead_not(string("</")) |> choice([parsec(:xml), text]))
  #           |> concat(closing_tag)
  #           |> wrap()
end