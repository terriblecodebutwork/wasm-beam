defmodule LexerHelper do
  import NimbleParsec

  def possible(comb, to_poss) do
    comb
    |> repeat(to_poss)
    |> lookahead_not(to_poss)
  end
end