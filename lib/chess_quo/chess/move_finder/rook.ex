defmodule ChessQuo.MoveFinder.Rook do
  alias ChessQuo.Chess.Piece
  alias ChessQuo.Chess.MoveFinder.DirectionMoves

  def valid_moves(game, %Piece{piece: :rook} = rook, index) do
    moves = []

    moves = moves ++ DirectionMoves.up_moves(game, index, rook)

    moves = moves ++ DirectionMoves.down_moves(game, index, rook)

    moves = moves ++ DirectionMoves.left_moves(game, index, rook)

    moves = moves ++ DirectionMoves.right_moves(game, index, rook)

    moves
  end
end
