defmodule EasyChess.Chess.MoveGenerator do
  @moduledoc """
  Provides functions for generating legal moves for a given board.
  """

  @doc """
  Calculates all valid moves for a piece at a given position on the board
  """
  def valid_moves(board, board_index) do
    piece = Enum.at(board["squares"], board_index)

    case piece do
      %EasyChess.Chess.Piece{type: type, color: color} ->
        calculate_moves(board, board_index, type, color)

      %{"type" => type, "color" => color} ->
        calculate_moves(board, board_index, type, color)

      nil ->
        []
    end
  end

  defp calculate_moves(board, board_index, "pawn", color) do
    direction = if color == :white, do: -1, else: 1
    {row, col} = EasyChess.Chess.Board.index_to_row_col(board_index)

    # Use `with` to handle forward moves
    moves =
      with forward_moves <- check_forward_move(board, row, col, direction),
           double_forward_moves <- check_double_forward_move(board, row, col, direction) do
        forward_moves ++ double_forward_moves
      end

    moves
  end

  defp calculate_moves(_board, _board_index, _type, _color) do
    []
  end

  defp check_forward_move(board, row, col, direction) do
    forward_index = EasyChess.Chess.Board.row_col_to_index(row + direction, col)

    if Enum.at(board["squares"], forward_index) == nil do
      [forward_index]
    else
      []
    end
  end

  defp check_double_forward_move(board, row, col, direction) do
    starting_row = if direction == 1, do: 1, else: 6
    dbl_forward_index = EasyChess.Chess.Board.row_col_to_index(row + 2 * direction, col)

    if row == starting_row and Enum.at(board["squares"], dbl_forward_index) == nil do
      [dbl_forward_index]
    else
      []
    end
  end

end
