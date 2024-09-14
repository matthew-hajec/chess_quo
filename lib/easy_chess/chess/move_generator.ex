defmodule EasyChess.Chess.MoveGenerator do
  @moduledoc """
  Provides functions for generating legal moves for a given board.
  """

  @doc """
  Calculates all valid moves for a piece at a given position on the board
  """
  def valid_moves(board, board_index) do
    piece = Enum.at(board.squares, board_index)

    case piece do
      %EasyChess.Chess.Piece{type: type, color: color} ->
        calculate_moves(board, board_index, type, color)

      nil ->
        []
    end
  end

  defp calculate_moves(board, board_index, :pawn, color) do
    # Calculate the moves for a pawn
    moves = []
    direction = if color == :white, do: 1, else: -1
    {row, col} = EasyChess.Chess.Board.index_to_row_col(board_index)

    # Check if the pawn can move forward
    moves =
      if (row + direction) in 0..7 do
        forward_index = EasyChess.Chess.Board.row_col_to_index(row + direction, col)

        if Enum.at(board.squares, forward_index) == nil do
          [forward_index | moves]
        else
          moves
        end
      end

    # Check if the pawn can move forward two squares
    starting_row = if color == :white, do: 1, else: 6

    moves =
      if row == starting_row do
        forward_index = EasyChess.Chess.Board.row_col_to_index(row + 2 * direction, col)

        if Enum.at(board.squares, forward_index) == nil do
          [forward_index | moves]
        else
          moves
        end
      end

    moves
  end

  defp calculate_moves(_board, _board_index, _type, _color) do
    []
  end
end
