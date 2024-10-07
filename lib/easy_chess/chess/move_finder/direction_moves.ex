defmodule EasyChess.Chess.MoveFinder.DirectionMoves do
  alias EasyChess.Chess.{Game, Move, Piece}
  alias EasyChess.Chess.MoveFinder.Helpers

  def generate_moves(game, index, piece, rank_delta, file_delta) do
    {rank, file} = Helpers.rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      new_rank = rank + i * rank_delta
      new_file = file + i * file_delta
      current_index = Helpers.index(new_rank, new_file)

      if !Helpers.valid_position?(current_index, new_rank, new_file) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece, current_index) | acc]}
        end
      end
    end)
  end

  def up_moves(game, index, piece) do
    generate_moves(game, index, piece, 1, 0)
  end

  def down_moves(game, index, piece) do
    generate_moves(game, index, piece, -1, 0)
  end

  def left_moves(game, index, piece) do
    generate_moves(game, index, piece, 0, -1)
  end

  def right_moves(game, index, piece) do
    generate_moves(game, index, piece, 0, 1)
  end

  def up_right_moves(game, index, piece) do
    generate_moves(game, index, piece, 1, 1)
  end

  def up_left_moves(game, index, piece) do
    generate_moves(game, index, piece, 1, -1)
  end

  def down_right_moves(game, index, piece) do
    generate_moves(game, index, piece, -1, 1)
  end

  def down_left_moves(game, index, piece) do
    generate_moves(game, index, piece, -1, -1)
  end
end
