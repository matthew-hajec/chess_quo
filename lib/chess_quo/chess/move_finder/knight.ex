defmodule ChessQuo.MoveFinder.Knight do
  alias ChessQuo.Chess.{Game, Piece, Move}
  alias ChessQuo.Chess.MoveFinder.Helpers

  def valid_moves(game, %Piece{piece: :knight} = knight, index) do
    moves = l_moves(game, index, knight)

    moves
  end

  defp l_moves(game, index, piece) do
    start_rank = div(index, 8)
    start_file = rem(index, 8)

    offsets = [
      {-1, 2},
      {-2, 1},
      {-2, -1},
      {-1, -2},
      {1, -2},
      {2, -1},
      {2, 1},
      {1, 2}
    ]

    Enum.reduce_while(offsets, [], fn {rank_offset, file_offset}, acc ->
      rank = start_rank + rank_offset
      file = start_file + file_offset

      current_index = rank * 8 + file

      if !Helpers.valid_position?(current_index, rank, file) do
        {:cont, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:cont, acc}

          %Piece{color: color} when color != piece.color ->
            {:cont, [Move.new(index, current_index, piece, current_index) | acc]}
        end
      end
    end)
  end
end
