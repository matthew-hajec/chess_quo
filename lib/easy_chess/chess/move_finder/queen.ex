defmodule EasyChess.MoveFinder.Queen do
  alias EasyChess.Chess.{Piece, MoveFinder}

  def valid_moves(game, %Piece{piece: :queen} = queen, index) do
    moves = []

    moves = MoveFinder.up_moves(game, index, queen) ++ moves
    moves = MoveFinder.down_moves(game, index, queen) ++ moves
    moves = MoveFinder.left_moves(game, index, queen) ++ moves
    moves = MoveFinder.right_moves(game, index, queen) ++ moves
    moves = MoveFinder.up_left_moves(game, index, queen) ++ moves
    moves = MoveFinder.up_right_moves(game, index, queen) ++ moves
    moves = MoveFinder.down_left_moves(game, index, queen) ++ moves
    moves = MoveFinder.down_right_moves(game, index, queen) ++ moves

    moves
  end
end
