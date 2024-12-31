defmodule ChessQuo.Chess.Move do
  @moduledoc """
  Contains the definition of a move
  """

  alias ChessQuo.Chess.Move, as: Move
  alias ChessQuo.Chess.Piece, as: Piece
  alias ChessQuo.GameTypes, as: Types

  @type t :: %Move{
          from: non_neg_integer(),
          to: non_neg_integer(),
          piece: %Piece{},
          captures: non_neg_integer(),
          castle_side: Types.castle_side(),
          promote_to: Types.piece_type()
        }

  @derive [Poison.Encoder]
  defstruct [:from, :to, :piece, :captures, :castle_side, :promote_to]

  defimpl Poison.Decoder do
    def decode(
          %Move{
            from: from,
            to: to,
            piece: piece,
            captures: captures,
            castle_side: castle_side,
            promote_to: promote_to
          },
          _opts
        ) do
      piece = Poison.decode!(Poison.encode!(piece), as: %Piece{})

      %Move{
        from: from,
        to: to,
        piece: piece,
        captures: captures,
        castle_side: castle_side,
        promote_to: promote_to
      }
    end
  end

  @doc """
  Creates a new move.
  """
  @spec new(
          non_neg_integer(),
          non_neg_integer(),
          %Piece{},
          Types.castle_side() | nil,
          Types.piece_type() | nil
        ) :: %Move{}
  def new(from, to, piece, captures \\ nil, castle_side \\ nil, promote_to \\ nil) do
    %Move{
      from: from,
      to: to,
      piece: piece,
      captures: captures,
      castle_side: castle_side,
      promote_to: promote_to
    }
  end
end
