defmodule EasyChess.Chess.MoveFinder do
  @moduledoc """
  Provides functions to find valid moves for all pieces on the board.
  """

  alias EasyChess.Chess.{Game, Piece, Move}

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
    moves = if validating do
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

    current_player_moves = Enum.filter(valid_moves, fn move ->
      move.piece.color == color
    end)

    # Check if the king is in check
    in_check = king_in_check?(game, color)

    IO.inspect("the #{color} king is in check: #{in_check}")
    IO.inspect("valid_moves: #{inspect current_player_moves}")

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
    king_index = Enum.find_index(game.board, fn piece ->
      piece == %Piece{piece: :king, color: color}
    end)

    # Generate all moves with the `validating` flag set to true
    all_moves = find_valid_moves(game, 0, [], true)

    # Filter moves to include only the opponent's moves
    opponent_moves = Enum.filter(all_moves, fn move ->
      move.piece.color != color
    end)

    # Check if any opponent move can attack the king's position
    Enum.any?(opponent_moves, fn move ->
      move.to == king_index
    end)
  end



  def in_bounds?(index) do
    index >= 0 and index <= 63
  end

  def rank_and_file(index) do
    {div(index, 8), rem(index, 8)}
  end

  def index(rank, file) do
    rank * 8 + file
  end

  def valid_rank?(rank) do
    rank >= 0 and rank <= 7
  end

  def valid_file?(file) do
    file >= 0 and file <= 7
  end

  @doc """
  Returns "up" moves for a piece up until the edge of the board.

  We define "up" moves as moves where the piece will move to a greater rank. (e.g. from A1 to A2)

  An up move can be blocked by a piece of the same color, but not by a piece of the opposite color.
  """
  def up_moves(game, index, piece) do
    # Start searching from the rank above the rank of the piece
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      new_rank = rank + i
      current_index = index(new_rank, file)

      if !in_bounds?(current_index) or !valid_file?(file) or !valid_rank?(rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def down_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      new_rank = rank - i
      current_index = index(new_rank, file)

      if !in_bounds?(current_index) or !valid_file?(file) or !valid_rank?(rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def left_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      new_file = file - i
      current_index = index(rank, new_file)

      if !in_bounds?(current_index) or !valid_file?(new_file) or !valid_rank?(rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def right_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      new_file = file + i
      current_index = index(rank, new_file)

      if !in_bounds?(current_index) or !valid_file?(new_file) or !valid_rank?(rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def up_right_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      next_rank = rank + i
      next_file = file + i
      current_index = index(next_rank, next_file)

      if !in_bounds?(current_index) or !valid_file?(next_file) or !valid_rank?(next_rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def up_left_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      next_rank = rank + i
      next_file = file - i
      current_index = index(next_rank, next_file)

      if !in_bounds?(current_index) or !valid_file?(next_file) or !valid_rank?(next_rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def down_right_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      next_rank = rank - i
      next_file = file + i
      current_index = index(next_rank, next_file)

      if !in_bounds?(current_index) or !valid_file?(next_file) or !valid_rank?(next_rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end

  def down_left_moves(game, index, piece) do
    {rank, file} = rank_and_file(index)

    Enum.reduce_while(1..7, [], fn i, acc ->
      next_rank = rank - i
      next_file = file - i
      current_index = index(next_rank, next_file)

      if !in_bounds?(current_index) or !valid_file?(next_file) or !valid_rank?(next_rank) do
        {:halt, acc}
      else
        case Game.at(game, current_index) do
          nil ->
            {:cont, [Move.new(index, current_index, piece) | acc]}

          %Piece{color: color} when color == piece.color ->
            {:halt, acc}

          %Piece{color: color} when color != piece.color ->
            {:halt, [Move.new(index, current_index, piece) | acc]}
        end
      end
    end)
  end
end
