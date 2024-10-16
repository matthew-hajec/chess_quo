defmodule ChessQuo.MoveFinder.Queen do
  alias ChessQuo.Chess.Piece
  alias ChessQuo.Chess.MoveFinder.DirectionMoves

  def valid_moves(game, %Piece{piece: :queen} = queen, index) do
    moves = []

    moves = DirectionMoves.up_moves(game, index, queen) ++ moves
    moves = DirectionMoves.down_moves(game, index, queen) ++ moves
    moves = DirectionMoves.left_moves(game, index, queen) ++ moves
    moves = DirectionMoves.right_moves(game, index, queen) ++ moves
    moves = DirectionMoves.up_left_moves(game, index, queen) ++ moves
    moves = DirectionMoves.up_right_moves(game, index, queen) ++ moves
    moves = DirectionMoves.down_left_moves(game, index, queen) ++ moves
    moves = DirectionMoves.down_right_moves(game, index, queen) ++ moves

    moves
  end
end
