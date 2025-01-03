defmodule ChessQuo.Chess.Piece do
  @moduledoc """
  Contains the definition of a chess piece.
  """

  alias ChessQuo.GameTypes, as: Types
  alias ChessQuo.Chess.Piece, as: Piece

  @type t :: %Piece{
          color: Types.color(),
          piece: Types.piece_type()
        }

  @derive [Poison.Encoder]
  defstruct [:color, :piece]

  defimpl Poison.Decoder do
    def decode(%Piece{color: color, piece: piece}, _opts) do
      %Piece{
        color: String.to_existing_atom(color),
        piece: String.to_existing_atom(piece)
      }
    end
  end

  @doc """
  Creates a new piece.
  """
  @spec new(Types.color(), Types.piece_type()) :: %Piece{}
  def new(color, piece) do
    %Piece{color: color, piece: piece}
  end

  @doc """
  Converts a string to a chess piece atom if valid, otherwise returns `nil`.

  Valid pieces: `:pawn`, `:knight`, `:bishop`, `:rook`, `:queen`, `:king`.
  """
  @spec string_to_piece(String.t()) :: :pawn | :knight | :bishop | :rook | :queen | :king | nil
  def string_to_piece(piece) do
    case piece do
      "pawn" -> :pawn
      "knight" -> :knight
      "bishop" -> :bishop
      "rook" -> :rook
      "queen" -> :queen
      "king" -> :king
      _ -> nil
    end
  end
end
