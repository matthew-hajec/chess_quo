defmodule ChessQuo.MoveFinder.Bishop do
  alias ChessQuo.Chess.Piece
  alias ChessQuo.Chess.MoveFinder.DirectionMoves

  def valid_moves(game, %Piece{piece: :bishop} = bishop, index) do
    moves = []

    moves = moves ++ DirectionMoves.up_right_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.up_left_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.down_right_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.down_left_moves(game, index, bishop)

    moves
  end
end
