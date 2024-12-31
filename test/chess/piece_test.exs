defmodule PieceTest do
  use ExUnit.Case

  alias ChessQuo.Chess.Piece

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
  end
end
