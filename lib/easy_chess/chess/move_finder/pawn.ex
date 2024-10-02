defmodule EasyChess.MoveFinder.Pawn do
  alias EasyChess.Chess.{Game, Piece, Move, MoveFinder}

  def valid_moves(game, %Piece{piece: :pawn} = pawn, index) do
    moves = []

    move = single_move(game, index, pawn)
    moves = if move != nil, do: [move | moves], else: moves

    move = double_move(game, index, pawn)
    moves = if move != nil, do: [move | moves], else: moves

    move = right_diagonal_capture(game, index, pawn)
    moves = if move != nil, do: [move | moves], else: moves

    move = left_diagonal_capture(game, index, pawn)
    moves = if move != nil, do: [move | moves], else: moves

    move = en_passant_capture(game, index, pawn)
    moves = if move != nil, do: [move | moves], else: moves

    moves
  end

  defp single_move(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    # Get the direction the pawn should move
    direction = pawn_direction(color)

    # Get the index of the square in front of the pawn
    single_forward_idx = index + 8 * direction

    is_valid =
      MoveFinder.in_bounds?(single_forward_idx) and Game.at(game, single_forward_idx) == nil

    # Check if the square in front of the pawn is empty
    if is_valid do
      # Create a new move
      %Move{from: index, to: single_forward_idx, piece: pawn}
    end
  end

  defp double_move(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    # Get the direction the pawn should move
    direction = pawn_direction(color)

    # Get the index of the square two squares in front of the pawn
    double_forward_idx = index + 16 * direction

    # Double jumping is allowed only if the pawn is in its starting position
    on_starting_rank =
      (color == :white and index >= 8 and index <= 15) or
        (color == :black and index >= 48 and index <= 55)

    # Check if the pawn can move two squares forward
    is_valid =
      on_starting_rank and
        MoveFinder.in_bounds?(double_forward_idx) and
        Game.at(game, double_forward_idx) == nil and
        single_move(game, index, pawn) != nil

    if is_valid do
      %Move{from: index, to: double_forward_idx, piece: pawn}
    end
  end

  defp right_diagonal_capture(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    # Get the direction the pawn should move
    direction = pawn_direction(color)

    # Get the rank and file of the pawn
    {rank, file} = MoveFinder.rank_and_file(index)

    forward_rank = rank + direction
    right_file = file + 1

    right_idx = MoveFinder.index(forward_rank, right_file)

    # Check if the pawn can capture a piece to the right
    is_valid =
      MoveFinder.in_bounds?(right_idx) and
        MoveFinder.valid_rank?(forward_rank) and
        MoveFinder.valid_file?(right_file) and
        Game.at(game, right_idx) != nil and
        Game.at(game, right_idx).color != color

    if is_valid do
      %Move{from: index, to: right_idx, piece: pawn}
    end
  end

  defp left_diagonal_capture(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    # Get the direction the pawn should move
    direction = pawn_direction(color)

    # Get the rank and file of the pawn
    {rank, file} = MoveFinder.rank_and_file(index)

    forward_rank = rank + direction
    left_file = file - 1

    left_idx = MoveFinder.index(forward_rank, left_file)

    # Check if the pawn can capture a piece to the right
    is_valid =
      MoveFinder.in_bounds?(left_idx) and
        MoveFinder.valid_rank?(forward_rank) and
        MoveFinder.valid_file?(left_file) and
        Game.at(game, left_idx) != nil and
        Game.at(game, left_idx).color != color

    if is_valid do
      %Move{from: index, to: left_idx, piece: pawn}
    end
  end

  defp en_passant_capture(game, index, %Piece{color: color, piece: :pawn} = pawn) do
    # Get the direction the pawn should move
    direction = pawn_direction(color)
    opponent_direction = direction * -1

    # Check the last move to see if it was a double move by an opponent's pawn
    previous_move = game.previous_move

    is_double_pawn_move =
      previous_move != nil and
        previous_move.piece.piece == :pawn and
        previous_move.from + 16 * opponent_direction == previous_move.to

    if is_double_pawn_move do
      # Determine if the move landed to the left or right of the current pawn
      one_left = index - 1 * direction
      one_right = index + 1 * direction

      # Check if the pawn can capture en passant to the left
      is_valid_left =
        MoveFinder.in_bounds?(one_left) and
          Game.at(game, one_left) == previous_move.piece

      # Check if the pawn can capture en passant to the right
      is_valid_right =
        MoveFinder.in_bounds?(one_right) and
          Game.at(game, one_right) == previous_move.piece

      # Determine the destination square for the en passant capture
      destination_right = index + 9 * direction
      destination_left = index + 7 * direction

      if is_valid_left do
        %Move{from: index, to: destination_left, piece: pawn}
      else
        if is_valid_right do
          %Move{from: index, to: destination_right, piece: pawn}
        end
      end
    end
  end

  defp pawn_direction(:white), do: 1
  defp pawn_direction(:black), do: -1
end
