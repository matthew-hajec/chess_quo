# test/game_test.exs
defmodule GameTest do
  use ExUnit.Case
  import EasyChess.Chess.Sigil

  alias EasyChess.Chess.{Game, Piece, Move}

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
  end
end