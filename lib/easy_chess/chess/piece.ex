defmodule EasyChess.Chess.Piece do
  @moduledoc """
  Contains the definition of a chess piece.
  """

  @valid_colors [:white, :black]
  @valid_pieces [:pawn, :rook, :knight, :bishop, :queen, :king]

  defstruct color: :white,
            piece: :pawn

  @doc """
  Creates a new piece.
  """
  def new(color, piece) do
    if Enum.member?(@valid_colors, color) and Enum.member?(@valid_pieces, piece) do
      %EasyChess.Chess.Piece{color: color, piece: piece}
    else
      raise ArgumentError, "Invalid color or piece"
    end
  end
end
