defmodule ChessQuo.Chess.Piece do
  @moduledoc """
  Contains the definition of a chess piece.
  """

  @valid_colors [:white, :black]
  @valid_pieces [:pawn, :rook, :knight, :bishop, :queen, :king]

  @derive [Poison.Encoder]
  defstruct color: :white,
            piece: :pawn

  defimpl Poison.Decoder do
    def decode(%ChessQuo.Chess.Piece{color: color, piece: piece}, _opts) do
      %ChessQuo.Chess.Piece{
        color: String.to_existing_atom(color),
        piece: String.to_existing_atom(piece)
      }
    end
  end

  @doc """
  Creates a new piece.
  """
  def new(color, piece) do
    if Enum.member?(@valid_colors, color) and Enum.member?(@valid_pieces, piece) do
      %ChessQuo.Chess.Piece{color: color, piece: piece}
    else
      raise ArgumentError, "Invalid color or piece"
    end
  end
end
