defmodule EasyChess.Chess.Board do
  @moduledoc """
  Contains a struct representing a chess board.
  """
  @derive Jason.Encoder
  defstruct squares: List.duplicate(nil, 64)

  @doc """
  Initializes a new chess board with the default starting position.
  """
  def new do
    %EasyChess.Chess.Board{squares: initialize_board()}
  end

  defp initialize_board do
    # Initialize the default starting position for all pieces
    [
      %EasyChess.Chess.Piece{type: :rook, color: :black},
      %EasyChess.Chess.Piece{type: :knight, color: :black},
      %EasyChess.Chess.Piece{type: :bishop, color: :black},
      %EasyChess.Chess.Piece{type: :queen, color: :black},
      %EasyChess.Chess.Piece{type: :king, color: :black},
      %EasyChess.Chess.Piece{type: :bishop, color: :black},
      %EasyChess.Chess.Piece{type: :knight, color: :black},
      %EasyChess.Chess.Piece{type: :rook, color: :black},
    ] ++ pawn_row(:black) ++ List.duplicate(nil, 32) ++ pawn_row(:white) ++ [
      %EasyChess.Chess.Piece{type: :rook, color: :white},
      %EasyChess.Chess.Piece{type: :knight, color: :white},
      %EasyChess.Chess.Piece{type: :bishop, color: :white},
      %EasyChess.Chess.Piece{type: :queen, color: :white},
      %EasyChess.Chess.Piece{type: :king, color: :white},
      %EasyChess.Chess.Piece{type: :bishop, color: :white},
      %EasyChess.Chess.Piece{type: :knight, color: :white},
      %EasyChess.Chess.Piece{type: :rook, color: :white},
    ]
  end

  defp pawn_row(color) do
    Enum.map(1..8, fn _ -> %EasyChess.Chess.Piece{type: :pawn, color: color} end)
  end

  def index_to_row_col(index) do
    {div(index, 8), rem(index, 8)}
  end

  def row_col_to_index(row, col) do
    row * 8 + col
  end

  def encode(board) do
    Jason.encode(board)
  end

  def decode(board) do
    Jason.decode(board)
  end
end
