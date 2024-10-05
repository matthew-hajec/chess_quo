defmodule EasyChess.MoveFinder.Bishop do
  alias EasyChess.Chess.Piece
  alias EasyChess.Chess.MoveFinder.DirectionMoves

  def valid_moves(game, %Piece{piece: :bishop} = bishop, index) do
    moves = []

    moves = moves ++ DirectionMoves.up_right_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.up_left_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.down_right_moves(game, index, bishop)

    moves = moves ++ DirectionMoves.down_left_moves(game, index, bishop)

    moves
  end
end
