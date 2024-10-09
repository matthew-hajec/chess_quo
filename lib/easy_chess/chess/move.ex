defmodule EasyChess.Chess.Move do
  @derive [Poison.Encoder]
  defstruct from: 0,
            to: 0,
            piece: nil,
            # Optional, will be the integer index of the piece captured
            captures: nil

  defimpl Poison.Decoder do
    def decode(%EasyChess.Chess.Move{from: from, to: to, piece: piece, captures: captures}, _opts) do
      piece = Poison.decode!(Poison.encode!(piece), as: %EasyChess.Chess.Piece{})

      %EasyChess.Chess.Move{
        from: from,
        to: to,
        piece: piece,
        captures: captures
      }
    end
  end

  @doc """
  Creates a new move.
  """
  def new(from, to, piece, captures \\ nil) do
    %EasyChess.Chess.Move{from: from, to: to, piece: piece, captures: captures}
  end
end
