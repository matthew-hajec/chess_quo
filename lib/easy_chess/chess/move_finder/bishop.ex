defmodule EasyChess.MoveFinder.Bishop do
  alias EasyChess.Chess.{Piece, MoveFinder}

  def valid_moves(game, %Piece{piece: :bishop} = bishop, index) do
    moves = []

    moves = moves ++ MoveFinder.up_right_moves(game, index, bishop)

    moves = moves ++ MoveFinder.up_left_moves(game, index, bishop)

    moves = moves ++ MoveFinder.down_right_moves(game, index, bishop)

    moves = moves ++ MoveFinder.down_left_moves(game, index, bishop)

    moves
  end
end
