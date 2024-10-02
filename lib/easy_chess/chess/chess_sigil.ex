defmodule EasyChess.Chess.Sigil do
  @moduledoc """
  Defines a sigil for chess board representation.
  """

  @rank_to_index %{
    "a" => 0,
    "b" => 1,
    "c" => 2,
    "d" => 3,
    "e" => 4,
    "f" => 5,
    "g" => 6,
    "h" => 7
  }

  @doc """
  Defines a sigil for chess board representation.

  The sigil converts a string in chess notation to an integer representing the
  index of the square in a chess board.

  ## Examples

      iex> ~B"a1"
      0
      iex> ~B"h8"
      63
      iex> ~B"e4"
      28
  """
  def sigil_B(string, _opts) do
    [x, y] = String.graphemes(string)
    x = Map.get(@rank_to_index, x)
    y = String.to_integer(y) - 1

    x + y * 8
  end
end
