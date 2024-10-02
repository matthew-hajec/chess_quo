defmodule PieceTest do
  use ExUnit.Case

  alias EasyChess.Chess.Piece

  doctest Piece

  describe "Piece.new/2" do
    test "creates a piece with valid color and type" do
      piece = Piece.new(:white, :king)
      assert piece.color == :white
      assert piece.piece == :king

      piece = Piece.new(:black, :queen)
      assert piece.color == :black
      assert piece.piece == :queen
    end

    test "raises ArgumentError for invalid color" do
      assert_raise ArgumentError, fn ->
        Piece.new(:green, :king)
      end
    end

    test "raises ArgumentError for invalid piece type" do
      assert_raise ArgumentError, fn ->
        Piece.new(:white, :dragon)
      end
    end

    test "raises ArgumentError for invalid color and piece type" do
      assert_raise ArgumentError, fn ->
        Piece.new(:purple, :unicorn)
      end
    end
  end
end
