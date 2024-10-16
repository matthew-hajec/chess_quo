defmodule ChessQuo.Chess.MoveFinder do
  @moduledoc """
  Provides functions to find valid moves for all pieces on the board.
  """

  alias ChessQuo.Chess.{Game, Piece}
  alias ChessQuo.Chess.MoveFinder.{Helpers, CastleMove}

  @doc """
  Finds all valid moves for all pieces on the board.

  Returns a list of valid moves ordered by the "to" index of the move.
  """
  def find_valid_moves(game) do
    find_valid_moves(game, 0, [], false)
  end

  # Base case for the recursive function
  def find_valid_moves(game, 64, moves, validating) do
    # If we are validating, we should not remove moves that would put the king in check
    moves =
      if validating do
        moves
      else
        temp_moves = remove_check_moves(game, moves)
        temp_moves = CastleMove.generate(game, :white, :king) ++ temp_moves
        temp_moves = CastleMove.generate(game, :white, :queen) ++ temp_moves
        temp_moves = CastleMove.generate(game, :black, :king) ++ temp_moves
        temp_moves = CastleMove.generate(game, :black, :queen) ++ temp_moves

        temp_moves
      end

    # Finally, add castling moves
    # We add them here to prevent infinite recursion, since it relies on calling this function

    # Sort the moves by the "to" index
    Enum.sort_by(moves, & &1.to)
  end

  def find_valid_moves(game, index, moves, validating) do
    piece = Game.at(game, index)

    new_moves =
      case piece do
        %Piece{piece: :pawn} = pawn ->
          ChessQuo.MoveFinder.Pawn.valid_moves(game, pawn, index)

        %Piece{piece: :rook} = rook ->
          ChessQuo.MoveFinder.Rook.valid_moves(game, rook, index)

        %Piece{piece: :bishop} = bishop ->
          ChessQuo.MoveFinder.Bishop.valid_moves(game, bishop, index)

        %Piece{piece: :queen} = queen ->
          ChessQuo.MoveFinder.Queen.valid_moves(game, queen, index)

        %Piece{piece: :knight} = knight ->
          ChessQuo.MoveFinder.Knight.valid_moves(game, knight, index)

        %Piece{piece: :king} = king ->
          ChessQuo.MoveFinder.King.valid_moves(game, king, index)

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
    in_check = Helpers.king_in_check?(game, color)

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
      not Helpers.king_in_check?(game_after_move, move.piece.color)
    end)
  end
end
