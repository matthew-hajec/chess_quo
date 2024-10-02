defmodule EasyChess.MoveFinder.Rook do
  alias EasyChess.Chess.{Piece, MoveFinder}

  def valid_moves(game, %Piece{piece: :rook} = rook, index) do
    moves = []

    moves = moves ++ MoveFinder.up_moves(game, index, rook)

    moves = moves ++ MoveFinder.down_moves(game, index, rook)

    moves = moves ++ MoveFinder.left_moves(game, index, rook)

    moves = moves ++ MoveFinder.right_moves(game, index, rook)

    moves
  end
end
