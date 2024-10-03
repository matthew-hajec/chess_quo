defmodule EasyChess.Chess.Move do
  @derive [Poison.Encoder]
  defstruct from: 0,
            to: 0,
            piece: nil

  defimpl Poison.Decoder do
    def decode(%EasyChess.Chess.Move{from: from, to: to, piece: piece}, _opts) do
      piece = Poison.decode!(Poison.encode!(piece), as: %EasyChess.Chess.Piece{})

      %EasyChess.Chess.Move{
        from: from,
        to: to,
        piece: piece
      }
    end
  end

  @doc """
  Creates a new move.
  """
  def new(from, to, piece) do
    %EasyChess.Chess.Move{from: from, to: to, piece: piece}
  end
end
