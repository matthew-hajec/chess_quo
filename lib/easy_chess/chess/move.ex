defmodule EasyChess.Chess.Move do
  defstruct from: 0,
            to: 0,
            piece: nil

  @doc """
  Creates a new move.
  """
  def new(from, to, piece) do
    %EasyChess.Chess.Move{from: from, to: to, piece: piece}
  end
end
