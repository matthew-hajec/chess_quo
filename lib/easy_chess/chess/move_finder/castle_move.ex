defmodule EasyChess.Chess.MoveFinder.CastleMove do
  alias EasyChess.Chess.{Game, Move}
  alias EasyChess.Chess.MoveFinder.Helpers

  def generate(game, color, side) do
    rook_idx = rook_start_idx(color, side)
    king_idx = king_start_idx(color)

    cond do
      # The rook and king must exist at the start indexes
      Game.at(game, rook_idx) == nil or Game.at(game, king_idx) == nil ->
        []

      # The king cannot have moved
      king_moved?(game, color) ->
        []

      # The rook cannot have moved
      rook_moved?(game, color, side) ->
        []

      # The path of the king must be clear (the starting square, squares moved through, and destination square)
      # Additionally, the king cannot be in check on any of the squares
      !king_path_clear?(game, color, side) ->
        []

      true ->
        new_king_idx = king_idx + if side == :king, do: 2, else: -2
        [Move.new(king_idx, new_king_idx, Game.at(game, king_idx), nil, side)]
    end
  end

  defp king_moved?(game, color) do
    # Check the move history for the king
    Enum.any?(game.move_history, fn move ->
      move.piece.color == color and move.piece.piece == :king
    end)
  end

  # Side can be :king or :queen
  defp rook_moved?(game, color, side) do
    start_idx = rook_start_idx(color, side)

    # Check the move history for the rook
    Enum.any?(game.move_history, fn move ->
      move.piece.color == color and move.piece.piece == :rook and move.from == start_idx
    end)
  end

  defp king_path_clear?(game, color, side) do
    king_index = king_start_idx(color)
    path_indexes = king_path_indexes(game, color, side)

    # Make sure the king is not in check on any of the squares
    if Helpers.king_in_check?(game, color) do
      false
    else
      Enum.all?(path_indexes, fn index ->
        if Game.at(game, index) != nil do
          false
        else
          # Test if the king is in check on the square
          test_move = Move.new(king_index, index, Game.at(game, king_index))
          test_game = Game.apply_move(game, test_move)

          test_in_check =
            Helpers.king_in_check?(test_game, color)

          if test_in_check do
            false
          else
            true
          end
        end
      end)
    end
  end

  # Is there a piece between the rook and the king?
  defp king_path_indexes(_game, color, side) do
    if color == :white do
      if side == :king do
        [5, 6]
      else
        [3, 2]
      end
    else
      if side == :king do
        [61, 62]
      else
        [59, 58]
      end
    end
  end

  defp rook_start_idx(color, side) do
    if color == :white do
      if side == :king do
        7
      else
        0
      end
    else
      if side == :king do
        63
      else
        56
      end
    end
  end

  defp king_start_idx(color) do
    if color == :white do
      4
    else
      60
    end
  end
end
