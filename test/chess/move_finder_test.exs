# test/move_validator_test.exs
defmodule MoveFinderTest do
  use ExUnit.Case
  alias EasyChess.Chess.{Game, Move, Piece, MoveFinder}
  import EasyChess.Chess.Sigil

  defp setup_game(pieces) do
    board = List.duplicate(nil, 64)
    board = setup_board(pieces, board)
    %Game{turn: :white, board: board}
  end

  defp setup_board(pieces, board_acc) do
    case pieces do
      [] ->
        board_acc

      [{index, piece} | rest] ->
        board = List.replace_at(board_acc, index, piece)
        setup_board(rest, board)
    end
  end

  describe "find_valid_moves/1 for pawns" do
    test "pawns can move one square forward" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :pawn)},
          {~B"e4", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid moves
      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"d4", ~B"d5", Piece.new(:white, :pawn)),
            Move.new(~B"e4", ~B"e3", Piece.new(:black, :pawn))
          ],
          & &1.to
        )

      assert valid_moves == found_moves
    end

    test "pawns blocked by pieces cannot move forward" do
      # In this position, only the pawn at h3 is unblocked
      game =
        setup_game([
          {~B"h2", Piece.new(:white, :pawn)},
          {~B"h3", Piece.new(:white, :pawn)},
          {~B"a7", Piece.new(:black, :pawn)},
          {~B"a6", Piece.new(:white, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"h3", ~B"h4", Piece.new(:white, :pawn))
          ],
          & &1.to
        )

      assert valid_moves == found_moves
    end

    test "pawns on the starting square can move two squares forward" do
      game =
        setup_game([
          {~B"h2", Piece.new(:white, :pawn)},
          {~B"c7", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"h2", ~B"h3", Piece.new(:white, :pawn)),
            Move.new(~B"h2", ~B"h4", Piece.new(:white, :pawn)),
            Move.new(~B"c7", ~B"c5", Piece.new(:black, :pawn)),
            Move.new(~B"c7", ~B"c6", Piece.new(:black, :pawn))
          ],
          & &1.to
        )

      assert valid_moves == found_moves
    end

    test "pawns at the edge of the board cannot move off the board" do
      game =
        setup_game([
          {~B"a8", Piece.new(:white, :pawn)},
          {~B"h1", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # There should be no valid pawn moves in this case
      assert Enum.empty?(found_moves)
    end

    test "pawns capturing diagonally" do
      game =
        setup_game([
          {~B"a3", Piece.new(:white, :pawn)},
          {~B"b4", Piece.new(:black, :pawn)},
          {~B"h3", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"a3", ~B"b4", Piece.new(:white, :pawn), ~B"b4"),
            Move.new(~B"a3", ~B"a4", Piece.new(:white, :pawn)),
            Move.new(~B"b4", ~B"a3", Piece.new(:black, :pawn), ~B"a3"),
            Move.new(~B"b4", ~B"b3", Piece.new(:black, :pawn)),
            Move.new(~B"h3", ~B"h2", Piece.new(:black, :pawn))
          ],
          & &1.to
        )

      assert found_moves == valid_moves
    end

    test "pawns cannot capture their own pieces" do
      game =
        setup_game([
          {~B"a3", Piece.new(:white, :pawn)},
          {~B"b4", Piece.new(:white, :pawn)},
          {~B"d5", Piece.new(:black, :pawn)},
          {~B"e6", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"a3", ~B"a4", Piece.new(:white, :pawn)),
            Move.new(~B"b4", ~B"b5", Piece.new(:white, :pawn)),
            Move.new(~B"d5", ~B"d4", Piece.new(:black, :pawn)),
            Move.new(~B"e6", ~B"e5", Piece.new(:black, :pawn))
          ],
          & &1.to
        )

      assert found_moves == valid_moves
    end

    test "en passant captures white pawn" do
      game =
        setup_game([
          {~B"a2", Piece.new(:white, :pawn)},
          {~B"b4", Piece.new(:black, :pawn)}
        ])

      # THIS CHANGES THE BOARD, A2 -> A4
      game = Game.apply_move(game, Move.new(~B"a2", ~B"a4", Piece.new(:white, :pawn)))

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            # En passant capture
            Move.new(~B"b4", ~B"a3", Piece.new(:black, :pawn), ~B"a4"),

            # White pawn forward
            Move.new(~B"a4", ~B"a5", Piece.new(:white, :pawn)),

            # Black pawn forward
            Move.new(~B"b4", ~B"b3", Piece.new(:black, :pawn))
          ],
          & &1.to
        )

      assert found_moves == valid_moves
    end

    test "en passant captures black pawn" do
      game =
        setup_game([
          {~B"h7", Piece.new(:black, :pawn)},
          {~B"g5", Piece.new(:white, :pawn)}
        ])

      # THIS CHANGES THE BOARD, H7 -> H5
      game = Game.apply_move(game, Move.new(~B"h7", ~B"h5", Piece.new(:black, :pawn)))

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            # En passant capture
            Move.new(~B"g5", ~B"h6", Piece.new(:white, :pawn), ~B"h5"),

            # Black pawn forward
            Move.new(~B"h5", ~B"h4", Piece.new(:black, :pawn)),

            # White pawn forward
            Move.new(~B"g5", ~B"g6", Piece.new(:white, :pawn))
          ],
          & &1.to
        )

      assert found_moves == valid_moves
    end

    test "a white pawn can promote on the last rank" do
      game = setup_game([
        # White pawn on the 7th rank
        {~B"a7", Piece.new(:white, :pawn)}
      ])

      found_moves = MoveFinder.find_valid_moves(game)

      # There should be 4 possible promotions
      promotion_moves = [
        Move.new(~B"a7", ~B"a8", Piece.new(:white, :pawn), nil, nil, :rook),
        Move.new(~B"a7", ~B"a8", Piece.new(:white, :pawn), nil, nil, :bishop),
        Move.new(~B"a7", ~B"a8", Piece.new(:white, :pawn), nil, nil, :knight),
        Move.new(~B"a7", ~B"a8", Piece.new(:white, :pawn), nil, nil, :queen)
      ]

      # Sort by `promote_to`, because `to` is the same for each move
      assert Enum.sort_by(promotion_moves, & &1.promote_to) == Enum.sort_by(found_moves, & &1.promote_to)
    end
  end

  describe "find_valid_moves/1 for rooks" do
    test "rooks can move vertically until the edge of the board" do
      game =
        setup_game([
          {~B"c5", Piece.new(:black, :rook)},
          {~B"d5", Piece.new(:white, :rook)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Valid vertical moves
      valid_moves = [
        # Black rook up
        Move.new(~B"c5", ~B"c8", Piece.new(:black, :rook)),
        Move.new(~B"c5", ~B"c7", Piece.new(:black, :rook)),
        Move.new(~B"c5", ~B"c6", Piece.new(:black, :rook)),

        # Black rook down
        Move.new(~B"c5", ~B"c4", Piece.new(:black, :rook)),
        Move.new(~B"c5", ~B"c3", Piece.new(:black, :rook)),
        Move.new(~B"c5", ~B"c2", Piece.new(:black, :rook)),
        Move.new(~B"c5", ~B"c1", Piece.new(:black, :rook)),

        # White rook up
        Move.new(~B"d5", ~B"d6", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"d7", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"d8", Piece.new(:white, :rook)),

        # White rook down
        Move.new(~B"d5", ~B"d4", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"d3", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"d2", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"d1", Piece.new(:white, :rook))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "rooks can move horizontally until the edge of the board" do
      game =
        setup_game([
          {~B"d4", Piece.new(:black, :rook)},
          {~B"d5", Piece.new(:white, :rook)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Valid horizontal moves
      valid_moves = [
        # Black rook left
        Move.new(~B"d4", ~B"a4", Piece.new(:black, :rook)),
        Move.new(~B"d4", ~B"b4", Piece.new(:black, :rook)),
        Move.new(~B"d4", ~B"c4", Piece.new(:black, :rook)),

        # Black rook right
        Move.new(~B"d4", ~B"e4", Piece.new(:black, :rook)),
        Move.new(~B"d4", ~B"f4", Piece.new(:black, :rook)),
        Move.new(~B"d4", ~B"g4", Piece.new(:black, :rook)),
        Move.new(~B"d4", ~B"h4", Piece.new(:black, :rook)),

        # White rook left
        Move.new(~B"d5", ~B"a5", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"b5", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"c5", Piece.new(:white, :rook)),

        # White rook right
        Move.new(~B"d5", ~B"e5", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"f5", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"g5", Piece.new(:white, :rook)),
        Move.new(~B"d5", ~B"h5", Piece.new(:white, :rook))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "rooks are blocked by pieces of the same color" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :rook)},
          {~B"d5", Piece.new(:white, :pawn)},
          {~B"d1", Piece.new(:white, :bishop)},
          {~B"a4", Piece.new(:white, :knight)},
          {~B"g4", Piece.new(:white, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define invalid vertical moves
      invalid_moves = [
        # Up
        Move.new(~B"d4", ~B"d5", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d6", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d7", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d8", Piece.new(:white, :rook)),

        # Down
        Move.new(~B"d4", ~B"d1", Piece.new(:white, :rook)),

        # Left
        Move.new(~B"d4", ~B"a4", Piece.new(:white, :rook)),

        # Right
        Move.new(~B"d4", ~B"g4", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"h4", Piece.new(:white, :rook))
      ]

      assert Enum.all?(invalid_moves, fn invalid_move ->
               invalid_move not in found_moves
             end)
    end

    test "rooks can capture opponent pieces" do
      game =
        setup_game([
          {~B"e6", Piece.new(:white, :rook)},
          {~B"e8", Piece.new(:black, :pawn)},
          {~B"b6", Piece.new(:black, :queen)},
          {~B"e5", Piece.new(:black, :bishop)},
          {~B"f6", Piece.new(:black, :knight)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      found_rook_moves =
        Enum.filter(found_moves, fn move ->
          move.piece == Piece.new(:white, :rook)
        end)

      # Define valid vertical capture moves
      valid_moves =
        Enum.sort_by(
          [
            # Up
            Move.new(~B"e6", ~B"e7", Piece.new(:white, :rook)),
            Move.new(~B"e6", ~B"e8", Piece.new(:white, :rook), ~B"e8"),

            # Down
            Move.new(~B"e6", ~B"e5", Piece.new(:white, :rook), ~B"e5"),

            # Left
            Move.new(~B"e6", ~B"d6", Piece.new(:white, :rook)),
            Move.new(~B"e6", ~B"c6", Piece.new(:white, :rook)),
            Move.new(~B"e6", ~B"b6", Piece.new(:white, :rook), ~B"b6"),

            # Right
            Move.new(~B"e6", ~B"f6", Piece.new(:white, :rook), ~B"f6")
          ],
          & &1.to
        )

      assert valid_moves == found_rook_moves
    end

    test "rooks cannot move past opponent pieces" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :rook)},
          {~B"d5", Piece.new(:black, :pawn)},
          {~B"d3", Piece.new(:black, :pawn)},
          {~B"c4", Piece.new(:black, :pawn)},
          {~B"e4", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define invalid vertical moves
      invalid_moves = [
        # Up
        Move.new(~B"d4", ~B"d6", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d7", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d8", Piece.new(:white, :rook)),

        # Down
        Move.new(~B"d4", ~B"d2", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"d1", Piece.new(:white, :rook)),

        # Left
        Move.new(~B"d4", ~B"b4", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"a4", Piece.new(:white, :rook)),

        # Right
        Move.new(~B"d4", ~B"f4", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"g4", Piece.new(:white, :rook)),
        Move.new(~B"d4", ~B"h4", Piece.new(:white, :rook))
      ]

      assert Enum.all?(invalid_moves, fn invalid_move ->
               invalid_move not in found_moves
             end)
    end
  end

  describe "find_valid_moves/1 for bishops" do
    test "bishops can move diagonally y=x" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :bishop)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid diagonal moves
      valid_moves = [
        Move.new(~B"d4", ~B"a1", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"b2", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"c3", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"e5", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"f6", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"g7", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"h8", Piece.new(:white, :bishop))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "bishops can move diagonally y=-x" do
      game =
        setup_game([
          {~B"d4", Piece.new(:black, :bishop)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid diagonal moves
      valid_moves = [
        Move.new(~B"d4", ~B"a7", Piece.new(:black, :bishop)),
        Move.new(~B"d4", ~B"b6", Piece.new(:black, :bishop)),
        Move.new(~B"d4", ~B"c5", Piece.new(:black, :bishop)),
        Move.new(~B"d4", ~B"e3", Piece.new(:black, :bishop)),
        Move.new(~B"d4", ~B"f2", Piece.new(:black, :bishop)),
        Move.new(~B"d4", ~B"g1", Piece.new(:black, :bishop))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "bishops can not jump over pieces of the same color" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :bishop)},
          {~B"e5", Piece.new(:white, :pawn)},
          {~B"c5", Piece.new(:white, :pawn)},
          {~B"e3", Piece.new(:white, :pawn)},
          {~B"c3", Piece.new(:white, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define invalid diagonal moves
      invalid_moves = [
        # Up and to the right
        Move.new(~B"d4", ~B"e5", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"f6", Piece.new(:white, :bishop)),

        # Up and to the left
        Move.new(~B"d4", ~B"c5", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"b6", Piece.new(:white, :bishop)),

        # Down and to the right
        Move.new(~B"d4", ~B"e3", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"f2", Piece.new(:white, :bishop)),

        # Down and to the left
        Move.new(~B"d4", ~B"c3", Piece.new(:white, :bishop)),
        Move.new(~B"d4", ~B"b2", Piece.new(:white, :bishop))
      ]

      assert Enum.all?(invalid_moves, fn invalid_move ->
               invalid_move not in found_moves
             end)
    end

    test "bishops can capture opponent pieces" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :bishop)},
          {~B"f2", Piece.new(:black, :pawn)},
          {~B"c3", Piece.new(:black, :queen)},
          {~B"f6", Piece.new(:black, :bishop)},
          {~B"b6", Piece.new(:black, :knight)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      found_bishop_moves =
        Enum.filter(found_moves, fn move ->
          move.piece == Piece.new(:white, :bishop)
        end)

      valid_moves =
        Enum.sort_by(
          [
            # Up/Right
            Move.new(~B"d4", ~B"e5", Piece.new(:white, :bishop)),
            Move.new(~B"d4", ~B"f6", Piece.new(:white, :bishop), ~B"f6"),

            # Down/Right
            Move.new(~B"d4", ~B"e3", Piece.new(:white, :bishop)),
            Move.new(~B"d4", ~B"f2", Piece.new(:white, :bishop), ~B"f2"),

            # Up/Left
            Move.new(~B"d4", ~B"c5", Piece.new(:white, :bishop)),
            Move.new(~B"d4", ~B"b6", Piece.new(:white, :bishop), ~B"b6"),

            # Down/Left
            Move.new(~B"d4", ~B"c3", Piece.new(:white, :bishop), ~B"c3")
          ],
          & &1.to
        )

      assert valid_moves == found_bishop_moves
    end

    test "bishops can not jump over opponent pieces" do
      game =
        setup_game([
          {~B"f6", Piece.new(:white, :bishop)},
          {~B"e7", Piece.new(:black, :pawn)},
          {~B"d4", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define invalid diagonal moves
      invalid_moves = [
        # Up and to the left
        Move.new(~B"f6", ~B"d8", Piece.new(:white, :bishop)),

        # Down and to the left
        Move.new(~B"f6", ~B"c3", Piece.new(:white, :bishop)),
        Move.new(~B"f6", ~B"b2", Piece.new(:white, :bishop))
      ]

      assert Enum.all?(invalid_moves, fn invalid_move ->
               invalid_move not in found_moves
             end)
    end
  end

  describe "find_valid_moves/1 for queens" do
    test "queens can move vertically until the edge of the board" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid vertical moves
      valid_moves = [
        # Up
        Move.new(~B"d4", ~B"d5", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"d6", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"d7", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"d8", Piece.new(:white, :queen)),

        # Down
        Move.new(~B"d4", ~B"d3", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"d2", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"d1", Piece.new(:white, :queen))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "queens can move horizontally until the edge of the board" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid horizontal moves
      valid_moves = [
        # Left
        Move.new(~B"d4", ~B"a4", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"b4", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"c4", Piece.new(:white, :queen)),

        # Right
        Move.new(~B"d4", ~B"e4", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"f4", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"g4", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"h4", Piece.new(:white, :queen))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "queens can move diagonally y=x" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid diagonal moves
      valid_moves = [
        Move.new(~B"d4", ~B"a1", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"b2", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"c3", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"e5", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"f6", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"g7", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"h8", Piece.new(:white, :queen))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "queens can move diagonally y=-x" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      # Define valid diagonal moves
      valid_moves = [
        Move.new(~B"d4", ~B"a7", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"b6", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"c5", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"e3", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"f2", Piece.new(:white, :queen)),
        Move.new(~B"d4", ~B"g1", Piece.new(:white, :queen))
      ]

      # Ensure all valid moves are in the found_moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end
  end

  describe "find_valid_moves/1 for knights" do
    test "knights jump in an l shape" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :knight)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves = [
        Move.new(~B"d4", ~B"c6", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"b5", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"b3", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"c2", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"e2", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"f3", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"f5", Piece.new(:white, :knight)),
        Move.new(~B"d4", ~B"e6", Piece.new(:white, :knight))
      ]

      # Valid moves and found moves should contain the same moves
      assert Enum.all?(valid_moves, fn valid_move ->
               valid_move in found_moves
             end)
    end

    test "knight cannot jump past board edge" do
      game =
        setup_game([
          {~B"a1", Piece.new(:white, :knight)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      only_valid_moves = [
        Move.new(~B"a1", ~B"c2", Piece.new(:white, :knight)),
        Move.new(~B"a1", ~B"b3", Piece.new(:white, :knight))
      ]

      # Ensure all valid moves are in the found_moves and no other moves are present
      assert Enum.all?(found_moves, fn move ->
               move in only_valid_moves
             end)
    end

    test "knight cannot jump into a piece of the same color" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :knight)},
          {~B"b5", Piece.new(:white, :pawn)},
          {~B"c6", Piece.new(:white, :pawn)},
          {~B"e6", Piece.new(:white, :pawn)},
          {~B"f5", Piece.new(:white, :pawn)},
          {~B"f3", Piece.new(:white, :pawn)},
          {~B"e2", Piece.new(:white, :pawn)},
          {~B"c2", Piece.new(:white, :pawn)},
          {~B"b3", Piece.new(:white, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      knight_moves =
        Enum.filter(found_moves, fn move ->
          move.piece == Piece.new(:white, :knight)
        end)

      # Night has no valid moves
      assert Enum.empty?(knight_moves)
    end

    test "knight can capture opponent pieces" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :knight)},
          {~B"b5", Piece.new(:black, :pawn)},
          {~B"c6", Piece.new(:black, :pawn)},
          {~B"e6", Piece.new(:black, :pawn)},
          {~B"f5", Piece.new(:black, :pawn)},
          {~B"f3", Piece.new(:black, :pawn)},
          {~B"e2", Piece.new(:black, :pawn)},
          {~B"c2", Piece.new(:black, :pawn)},
          {~B"b3", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      knight_moves =
        Enum.filter(found_moves, fn move ->
          move.piece.piece == :knight
        end)

      # Knight can capture all opponent pieces
      assert Enum.count(knight_moves) == 8
    end
  end

  describe "find_valid_moves/1 for kings" do
    test "kings move one square in all directions" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :king)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves = [
        Move.new(~B"d4", ~B"c3", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"d3", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"e3", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"c4", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"e4", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"c5", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"d5", Piece.new(:white, :king)),
        Move.new(~B"d4", ~B"e5", Piece.new(:white, :king))
      ]

      assert valid_moves == found_moves
    end

    test "kings can not move off the board" do
      game =
        setup_game([
          {~B"a1", Piece.new(:white, :king)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      valid_moves =
        Enum.sort_by(
          [
            Move.new(~B"a1", ~B"a2", Piece.new(:white, :king)),
            Move.new(~B"a1", ~B"b2", Piece.new(:white, :king)),
            Move.new(~B"a1", ~B"b1", Piece.new(:white, :king))
          ],
          & &1.to
        )

      assert valid_moves == found_moves
    end

    test "kings can capture opponent pieces" do
      game =
        setup_game([
          {~B"d4", Piece.new(:white, :king)},
          {~B"c3", Piece.new(:black, :pawn)},
          {~B"d3", Piece.new(:black, :pawn)},
          {~B"e3", Piece.new(:black, :pawn)},
          {~B"c5", Piece.new(:black, :pawn)},
          {~B"d5", Piece.new(:black, :pawn)},
          {~B"e5", Piece.new(:black, :pawn)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      king_moves =
        Enum.filter(found_moves, fn move ->
          move.piece.piece == :king
        end)

      # King can capture all opponent pieces
      assert Enum.count(king_moves) == 6
    end

    test "king cannot move into check" do
      game =
        setup_game([
          {~B"c4", Piece.new(:white, :king)},
          {~B"c2", Piece.new(:black, :bishop)},
          {~B"d8", Piece.new(:black, :queen)}
        ])

      found_moves = MoveFinder.find_valid_moves(game)

      white_king_moves =
        Enum.filter(found_moves, fn move ->
          move.piece.piece == :king && move.piece.color == :white
        end)

      # Can move to c3, b4,d5, and c5
      valid_king_moves =
        Enum.sort_by(
          [
            Move.new(~B"c4", ~B"c3", Piece.new(:white, :king)),
            Move.new(~B"c4", ~B"b4", Piece.new(:white, :king)),
            Move.new(~B"c4", ~B"b5", Piece.new(:white, :king)),
            Move.new(~B"c4", ~B"c5", Piece.new(:white, :king))
          ],
          & &1.to
        )

      assert white_king_moves == valid_king_moves
    end
  end

  describe "generate_moves/1 for castling move" do
    test "the king can castle to either side" do
      game =
        setup_game([
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},
          {~B"a1", Piece.new(:white, :rook)}
        ])

      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      expected_moves =
        [
          Move.new(~B"e1", ~B"g1", Piece.new(:white, :king), nil, :king),
          Move.new(~B"e1", ~B"c1", Piece.new(:white, :king), nil, :queen)
        ]

      assert Enum.sort_by(castling_moves, & &1.to) == Enum.sort_by(expected_moves, & &1.to)
    end

    test "the king can not castle if the king has moved" do
      game =
        setup_game([
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},
          {~B"a1", Piece.new(:white, :rook)}
        ])

      game = Game.apply_move(game, Move.new(~B"e1", ~B"e2", Piece.new(:white, :king)))
      # Move back
      game = Game.apply_move(game, Move.new(~B"e2", ~B"e1", Piece.new(:white, :king)))

      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      assert Enum.empty?(castling_moves)
    end

    test "the king can not castle if the rook has moved" do
      game =
        setup_game([
          # White Side
          {~B"a1", Piece.new(:white, :rook)},
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},

          # Black Side
          {~B"a8", Piece.new(:black, :rook)},
          {~B"e8", Piece.new(:black, :king)},
          {~B"h8", Piece.new(:black, :rook)}
        ])

      # White rook at a1 moves to a2 and back
      game = Game.apply_move(game, Move.new(~B"a1", ~B"a2", Piece.new(:white, :rook)))
      game = Game.apply_move(game, Move.new(~B"a2", ~B"a1", Piece.new(:white, :rook)))

      # Black rook at h8 moves to h3 and back
      game = Game.apply_move(game, Move.new(~B"h8", ~B"h3", Piece.new(:black, :rook)))
      game = Game.apply_move(game, Move.new(~B"h3", ~B"h8", Piece.new(:black, :rook)))

      # Generate moves
      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      expected_moves = [
        # White king to g1 king side
        Move.new(~B"e1", ~B"g1", Piece.new(:white, :king), nil, :king),

        # Black king to c8 queen side
        Move.new(~B"e8", ~B"c8", Piece.new(:black, :king), nil, :queen)
      ]

      assert Enum.sort_by(castling_moves, & &1.to) == Enum.sort_by(expected_moves, & &1.to)
    end

    test "the king can not castle if it is in check" do
      game =
        setup_game([
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},
          {~B"a1", Piece.new(:white, :rook)},

          # Knight attacking king
          {~B"d3", Piece.new(:black, :knight)}
        ])

      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      assert Enum.empty?(castling_moves)
    end

    test "the king can not castle a square in the path is in check" do
      game =
        setup_game([
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},
          {~B"a1", Piece.new(:white, :rook)},

          # Knight attacking d1 (in path of queen side castle)
          {~B"d3", Piece.new(:black, :knight)},

          # Rook attacking g1 (in path of king side castle)
          {~B"g8", Piece.new(:black, :rook)}
        ])

      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      assert Enum.empty?(castling_moves)
    end

    test "the king can castle if non-path squares are in check" do
      game =
        setup_game([
          {~B"e1", Piece.new(:white, :king)},
          {~B"h1", Piece.new(:white, :rook)},
          {~B"a1", Piece.new(:white, :rook)},

          # Bishop attacking b1
          {~B"f5", Piece.new(:black, :knight)},

          # Rook attacking the rook at h1
          {~B"h8", Piece.new(:black, :rook)}
        ])

      all_moves = MoveFinder.find_valid_moves(game)

      # Castle moves
      castling_moves =
        Enum.filter(all_moves, fn move ->
          move.castle_side != nil
        end)

      expected_moves =
        [
          Move.new(~B"e1", ~B"g1", Piece.new(:white, :king), nil, :king),
          Move.new(~B"e1", ~B"c1", Piece.new(:white, :king), nil, :queen)
        ]

      assert Enum.sort_by(castling_moves, & &1.to) == Enum.sort_by(expected_moves, & &1.to)
    end
  end
end
