defmodule EasyChess.MoveFinder.Pawn do
  alias EasyChess.Chess.{Game, Piece, Move}
  alias EasyChess.Chess.MoveFinder.Helpers

  def valid_moves(game, %Piece{piece: :pawn} = pawn, index) do
    moves = []

    moves = moves ++ single_move(game, index, pawn)
    moves = moves ++ double_move(game, index, pawn)
    moves = moves ++ diagonal_capture(game, index, pawn)
    moves = moves ++ en_passant_capture(game, index, pawn)

    moves = Enum.flat_map(moves, fn move ->
      if is_promotion?(move) do
        Enum.map([:rook, :knight, :bishop, :queen], fn type ->
          %{move | promote_to: type}
        end)
      else
        [move]
      end
    end)

    moves
  end

  defp is_promotion?(move) do
    {rank, _} = Helpers.rank_and_file(move.to)

    (move.piece.color == :white and rank == 7) or
      (move.piece.color == :black and rank == 0)
  end

  defp single_move(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    {rank, file} = Helpers.rank_and_file(index)

    direction = pawn_direction(color)

    forward_rank = rank + direction

    forward_idx = Helpers.index(forward_rank, file)

    is_valid =
      Helpers.valid_position?(forward_idx, forward_rank, file) and
        Game.at(game, forward_idx) == nil

    if is_valid do
      [%Move{from: index, to: forward_idx, piece: pawn}]
    else
      []
    end
  end

  defp double_move(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    {rank, file} = Helpers.rank_and_file(index)

    direction = pawn_direction(color)

    # Calculate the double forward rank
    double_forward_rank = rank + 2 * direction

    double_forward_idx = Helpers.index(double_forward_rank, file)

    # Calculate the single forward rank to check if the pawn can move two squares forward
    single_forward_rank = rank + direction

    single_forward_idx = Helpers.index(single_forward_rank, file)

    # Double jumping is allowed only if the pawn is in its starting position
    on_starting_rank =
      (color == :white and index >= 8 and index <= 15) or
        (color == :black and index >= 48 and index <= 55)

    # Check if the pawn can move two squares forward
    is_valid =
      Helpers.valid_position?(double_forward_idx, double_forward_rank, file) and
        Game.at(game, double_forward_idx) == nil and
        Game.at(game, single_forward_idx) == nil and
        on_starting_rank

    if is_valid do
      [%Move{from: index, to: double_forward_idx, piece: pawn}]
    else
      []
    end
  end

  defp diagonal_capture(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    {rank, file} = Helpers.rank_and_file(index)

    direction = pawn_direction(color)

    forward_rank = rank + direction

    # Calculate the right and left diagonal squares
    right_file = file + 1
    right_idx = Helpers.index(forward_rank, right_file)

    left_file = file - 1
    left_idx = Helpers.index(forward_rank, left_file)

    is_valid_right =
      Helpers.valid_position?(right_idx, forward_rank, right_file) and
        Game.at(game, right_idx) != nil and
        Game.at(game, right_idx).color != color

    is_valid_left =
      Helpers.valid_position?(left_idx, forward_rank, left_file) and
        Game.at(game, left_idx) != nil and
        Game.at(game, left_idx).color != color

    moves = []

    moves =
      moves ++
        if is_valid_right do
          [%Move{from: index, to: right_idx, piece: pawn, captures: right_idx}]
        else
          []
        end

    moves =
      moves ++
        if is_valid_left do
          [%Move{from: index, to: left_idx, piece: pawn, captures: left_idx}]
        else
          []
        end

    moves
  end

  defp en_passant_capture(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    {rank, file} = Helpers.rank_and_file(index)

    direction = pawn_direction(color)

    opponent_direction = direction * -1

    # Check the last move to see if it was a double move by an opponent's pawn
    previous_move = game.previous_move

    is_double_pawn_move =
      previous_move != nil and
        previous_move.piece.piece == :pawn and
        previous_move.from + 16 * opponent_direction == previous_move.to

    if is_double_pawn_move do
      left_file = file - 1
      left_idx = Helpers.index(rank, left_file)

      right_file = file + 1
      right_idx = Helpers.index(rank, right_file)

      # Check if the pawn can capture en passant to the left
      is_valid_left =
        Helpers.valid_position?(left_idx, rank, left_file) and
          Game.at(game, left_idx) == previous_move.piece

      # Check if the pawn can capture en passant to the right
      is_valid_right =
        Helpers.valid_position?(right_idx, rank, right_file) and
          Game.at(game, right_idx) == previous_move.piece

      # Determine the destination square for the en passant capture
      destination_left = Helpers.index(rank + direction, left_file)
      destination_right = Helpers.index(rank + direction, right_file)

      if is_valid_left do
        [%Move{from: index, to: destination_left, piece: pawn, captures: left_idx}]
      else
        if is_valid_right do
          [%Move{from: index, to: destination_right, piece: pawn, captures: right_idx}]
        else
          []
        end
      end
    else
      []
    end
  end

  defp pawn_direction(:white), do: 1
  defp pawn_direction(:black), do: -1
end
