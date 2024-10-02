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
    find_valid_moves(game, 0, [])
  end

  # Base case for the recursive function
  defp find_valid_moves(_game, 64, moves) do
    # Sort the moves by the "to" index
    Enum.sort_by(moves, & &1.to)
  end

  defp find_valid_moves(game, index, moves) do
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

    find_valid_moves(game, index + 1, moves ++ new_moves)
  end

  # Helper functions
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
    start_rank = div(index, 8) + 1

    Enum.reduce_while(start_rank..7, [], fn i, acc ->
      # We use `rem` to get the file of the current square
      current_index = i * 8 + rem(index, 8)

      if !in_bounds?(current_index) do
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
    # Start searching from the rank below the rank of the piece
    start_rank = div(index, 8) - 1

    Enum.reduce_while(start_rank..0//-1, [], fn i, acc ->
      # We use `rem` to get the file of the current square
      current_index = i * 8 + rem(index, 8)

      if !in_bounds?(current_index) do
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
    # Start searching from the file to the left of the piece
    start_file = rem(index, 8) - 1

    Enum.reduce_while(start_file..0//-1, [], fn i, acc ->
      # We use `div` to get the rank of the current square
      current_index = div(index, 8) * 8 + i

      if !in_bounds?(current_index) do
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
    # Start searching from the file to the right of the piece
    start_file = rem(index, 8) + 1

    Enum.reduce_while(start_file..7, [], fn i, acc ->
      # We use `div` to get the rank of the current square
      current_index = div(index, 8) * 8 + i

      if !in_bounds?(current_index) do
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
    start_rank = div(index, 8)
    start_file = rem(index, 8)

    Enum.reduce_while(1..7, [], fn i, acc ->
      current_rank = start_rank + i
      current_file = start_file + i

      current_index = current_rank * 8 + current_file

      if !in_bounds?(current_index) do
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
    start_rank = div(index, 8)
    start_file = rem(index, 8)

    Enum.reduce_while(1..7, [], fn i, acc ->
      current_rank = start_rank + i
      current_file = start_file - i

      current_index = current_rank * 8 + current_file

      if !in_bounds?(current_index) do
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
    start_rank = div(index, 8)
    start_file = rem(index, 8)

    Enum.reduce_while(1..7, [], fn i, acc ->
      current_rank = start_rank - i
      current_file = start_file + i

      current_index = current_rank * 8 + current_file

      if !in_bounds?(current_index) do
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
    start_rank = div(index, 8)
    start_file = rem(index, 8)

    Enum.reduce_while(1..7, [], fn i, acc ->
      current_rank = start_rank - i
      current_file = start_file - i

      current_index = current_rank * 8 + current_file

      if !in_bounds?(current_index) do
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
