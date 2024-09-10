defmodule EasyChess.Chess.Piece do
  @moduledoc """
  Contains a struct representing a piece.

  The accepted values for `type` are:
  - `:pawn`
  - `:rook`
  - `:bishop`
  - `:knight`
  - `:king`
  - `:queen`

  The accepted values for `color` are:
  - `:white`
  - `:black`
  """
  @derive Jason.Encoder
  defstruct [:type, :color]
end
