# test/game_test.exs
defmodule GameTest do
  use ExUnit.Case
  import ChessQuo.Chess.Sigil

  alias ChessQuo.Chess.{Game, Piece, Move}

  doctest Game

  describe "Game.new/0" do
    test "initializes a new game with correct defaults" do
      game = Game.new()
      assert game.turn == :white
      assert game.previous_move == nil
      assert length(game.board) == 64
    end

    test "initializes the board with correct piece positions" do
      game = Game.new()

      # White back rank (indices 0 to 7)
      assert %Piece{color: :white, piece: :rook} == Game.at(game, ~B"a1")
      assert %Piece{color: :white, piece: :knight} == Game.at(game, ~B"b1")
      assert %Piece{color: :white, piece: :bishop} == Game.at(game, ~B"c1")
      assert %Piece{color: :white, piece: :queen} == Game.at(game, ~B"d1")
      assert %Piece{color: :white, piece: :king} == Game.at(game, ~B"e1")
      assert %Piece{color: :white, piece: :bishop} == Game.at(game, ~B"f1")
      assert %Piece{color: :white, piece: :knight} == Game.at(game, ~B"g1")
      assert %Piece{color: :white, piece: :rook} == Game.at(game, ~B"h1")

      # White pawns (indices 8 to 15)
      for index <- 8..15 do
        assert %Piece{color: :white, piece: :pawn} == Game.at(game, index)
      end

      # Empty squares (indices 16 to 47)
      for index <- 16..47 do
        assert nil == Game.at(game, index)
      end

      # Black pawns (indices 48 to 55)
      for index <- 48..55 do
        assert %Piece{color: :black, piece: :pawn} == Game.at(game, index)
      end

      # Black back rank (indices 56 to 63)
      assert %Piece{color: :black, piece: :rook} == Game.at(game, ~B"a8")
      assert %Piece{color: :black, piece: :knight} == Game.at(game, ~B"b8")
      assert %Piece{color: :black, piece: :bishop} == Game.at(game, ~B"c8")
      assert %Piece{color: :black, piece: :queen} == Game.at(game, ~B"d8")
      assert %Piece{color: :black, piece: :king} == Game.at(game, ~B"e8")
      assert %Piece{color: :black, piece: :bishop} == Game.at(game, ~B"f8")
      assert %Piece{color: :black, piece: :knight} == Game.at(game, ~B"g8")
      assert %Piece{color: :black, piece: :rook} == Game.at(game, ~B"h8")
    end
  end

  describe "Game.at/2" do
    setup do
      game = Game.new()
      {:ok, game: game}
    end

    test "returns the correct piece at a given valid index", %{game: game} do
      # Test some specific indices
      assert %Piece{color: :white, piece: :rook} == Game.at(game, ~B"a1")
      assert %Piece{color: :white, piece: :pawn} == Game.at(game, ~B"e2")
      # Empty square
      assert nil == Game.at(game, 20)
      assert %Piece{color: :black, piece: :pawn} == Game.at(game, ~B"d7")
      assert %Piece{color: :black, piece: :king} == Game.at(game, ~B"e8")
    end

    test "raises ArgumentError for invalid indices", %{game: game} do
      assert_raise ArgumentError, fn -> Game.at(game, -1) end
      assert_raise ArgumentError, fn -> Game.at(game, 64) end
      assert_raise ArgumentError, fn -> Game.at(game, 100) end
    end
  end

  describe "Game.apply_move/2" do
    setup do
      game = Game.new()
      {:ok, game: game}
    end

    test "returns a new game with the correct piece moved" do
      game = Game.new()
      move = %Move{from: ~B"e2", to: ~B"e4", piece: %Piece{color: :white, piece: :pawn}}
      new_game = Game.apply_move(game, move)

      assert %Piece{color: :white, piece: :pawn} == Game.at(new_game, ~B"e4")
      assert nil == Game.at(new_game, ~B"e2")
    end

    test "capture move" do
      game = Game.new()

      # Prepare for capture move
      move = %Move{from: ~B"a2", to: ~B"a4", piece: %Piece{color: :white, piece: :pawn}}
      new_game = Game.apply_move(game, move)

      # Prepare for capture move
      move = %Move{from: ~B"b7", to: ~B"b5", piece: %Piece{color: :black, piece: :pawn}}
      new_game = Game.apply_move(new_game, move)

      # Capture move
      move = %Move{from: ~B"a4", to: ~B"b5", piece: %Piece{color: :white, piece: :pawn}}
      new_game = Game.apply_move(new_game, move)

      assert %Piece{color: :white, piece: :pawn} == Game.at(new_game, ~B"b5")
      assert nil == Game.at(new_game, ~B"a4")
      assert nil == Game.at(new_game, ~B"a2")
      assert nil == Game.at(new_game, ~B"b7")
    end

    test "capture move without landing on captured square" do
      # This is the case for en passant
      board = List.duplicate(nil, 64)

      # Set up the game for an en passant move
      board = List.replace_at(board, ~B"e2", %Piece{color: :white, piece: :pawn})
      board = List.replace_at(board, ~B"d4", %Piece{color: :black, piece: :pawn})

      # Create a new game with the board set up for en passant
      game = %Game{board: board, turn: :white, previous_move: nil}

      # Apply the double pawn move
      double_move = %Move{from: ~B"e2", to: ~B"e4", piece: %Piece{color: :white, piece: :pawn}}
      game = Game.apply_move(game, double_move)

      # Apply the en passant move
      en_passant = %Move{
        from: ~B"d4",
        to: ~B"e3",
        piece: %Piece{color: :white, piece: :pawn},
        captures: ~B"e4"
      }

      game = Game.apply_move(game, en_passant)

      # The pawn at e4 should be captured
      assert nil == Game.at(game, ~B"e4")
    end

    test "multiple moves are appended to the move history" do
      game = Game.new()
      move1 = %Move{from: ~B"e2", to: ~B"e4", piece: %Piece{color: :white, piece: :pawn}}
      move2 = %Move{from: ~B"e7", to: ~B"e5", piece: %Piece{color: :black, piece: :pawn}}
      new_game = Game.apply_move(game, move1)
      new_game = Game.apply_move(new_game, move2)

      assert [move2, move1] == new_game.move_history
    end

    test "applying a castling move moves the rook" do
      board = List.duplicate(nil, 64)

      board = List.replace_at(board, ~B"e1", Piece.new(:white, :king))
      board = List.replace_at(board, ~B"a1", Piece.new(:white, :rook))
      board = List.replace_at(board, ~B"h1", Piece.new(:white, :rook))

      # Create game from the board state
      game = %Game{board: board}

      # Create a move
      king_castle_move = Move.new(~B"e1", ~B"g1", Piece.new(:white, :king), nil, :king)
      queen_castle_move = Move.new(~B"e1", ~B"c1", Piece.new(:white, :king), nil, :queen)

      king_castle_game = Game.apply_move(game, king_castle_move)
      queen_castle_game = Game.apply_move(game, queen_castle_move)

      assert Enum.at(king_castle_game.board, ~B"f1") == Piece.new(:white, :rook)
      assert Enum.at(king_castle_game.board, ~B"g1") == Piece.new(:white, :king)

      assert Enum.at(queen_castle_game.board, ~B"d1") == Piece.new(:white, :rook)
      assert Enum.at(queen_castle_game.board, ~B"c1") == Piece.new(:white, :king)
    end

    test "applying a move changes the turn" do
      game = Game.new()
      move = %Move{from: ~B"e2", to: ~B"e4", piece: %Piece{color: :white, piece: :pawn}}
      new_game = Game.apply_move(game, move)

      assert new_game.turn == :black

      move = %Move{from: ~B"e7", to: ~B"e5", piece: %Piece{color: :black, piece: :pawn}}
      new_game = Game.apply_move(new_game, move)

      assert new_game.turn == :white
    end

    test "pawn promotion switches out the piece" do
      board = List.duplicate(nil, 64)

      board = List.replace_at(board, ~B"a7", Piece.new(:white, :pawn))

      game = %Game{board: board}

      move = Move.new(~B"a7", ~B"a8", Piece.new(:white, :pawn), nil, nil, :queen)

      game = Game.apply_move(game, move)

      assert Enum.at(game.board, ~B"a8") == Piece.new(:white, :queen)
    end
  end
end
