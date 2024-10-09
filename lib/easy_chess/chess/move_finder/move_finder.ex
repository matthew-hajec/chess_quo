defmodule EasyChess.Chess.MoveFinder do
  @moduledoc """
  Provides functions to find valid moves for all pieces on the board.
  """

  alias EasyChess.Chess.{Game, Piece}

  @doc """
  Finds all valid moves for all pieces on the board.

  Returns a list of valid moves ordered by the "to" index of the move.
  """
  def find_valid_moves(game) do
    find_valid_moves(game, 0, [], false)
  end

  # Base case for the recursive function
  defp find_valid_moves(game, 64, moves, validating) do
    # If we are validating, we need to remove moves that would put the king in check
    moves =
      if validating do
        moves
      else
        remove_check_moves(game, moves)
      end

    # Sort the moves by the "to" index
    Enum.sort_by(moves, & &1.to)
  end

  defp find_valid_moves(game, index, moves, validating) do
    piece = Game.at(game, index)

    new_moves =
      case piece do
        %Piece{piece: :pawn} = pawn ->
          EasyChess.MoveFinder.Pawn.valid_moves(game, pawn, index)

        %Piece{piece: :rook} = rook ->
          EasyChess.MoveFinder.Rook.valid_moves(game, rook, index)

        %Piece{piece: :bishop} = bishop ->
          EasyChess.MoveFinder.Bishop.valid_moves(game, bishop, index)

        %Piece{piece: :queen} = queen ->
          EasyChess.MoveFinder.Queen.valid_moves(game, queen, index)

        %Piece{piece: :knight} = knight ->
          EasyChess.MoveFinder.Knight.valid_moves(game, knight, index)

        %Piece{piece: :king} = king ->
          EasyChess.MoveFinder.King.valid_moves(game, king, index)

        _ ->
          []
      end

    find_valid_moves(game, index + 1, moves ++ new_moves, validating)
  end

  # Helper functions
  def game_condition(game) do
    # Determine the current player's color
    color = game.turn

    # Generate all valid moves for the current player
    valid_moves = find_valid_moves(game)

    current_player_moves =
      Enum.filter(valid_moves, fn move ->
        move.piece.color == color
      end)

    # Check if the king is in check
    in_check = king_in_check?(game, color)

    cond do
      in_check and current_player_moves == [] ->
        :checkmate

      not in_check and current_player_moves == [] ->
        :stalemate

      true ->
        :normal
    end
  end

  defp remove_check_moves(game, moves) do
    Enum.filter(moves, fn move ->
      # Apply the move to create a new game state
      game_after_move = Game.apply_move(game, move)

      # Check if our own king is in check after the move
      not king_in_check?(game_after_move, move.piece.color)
    end)
  end

  defp king_in_check?(game, color) do
    # Find the index of the king of the given color
    king_index =
      Enum.find_index(game.board, fn piece ->
        piece == %Piece{piece: :king, color: color}
      end)

    # Generate all moves with the `validating` flag set to true
    all_moves = find_valid_moves(game, 0, [], true)

    # Filter moves to include only the opponent's moves
    opponent_moves =
      Enum.filter(all_moves, fn move ->
        move.piece.color != color
      end)

    # Check if any opponent move can attack the king's position
    Enum.any?(opponent_moves, fn move ->
      move.to == king_index
    end)
  end
end
