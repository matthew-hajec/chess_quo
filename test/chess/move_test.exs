defmodule MoveTest do
  use ExUnit.Case

  alias EasyChess.Chess.{Move, Piece}

  doctest Move

  describe "Move.new/5" do
    test "creates a move with correct fields" do
      piece = Piece.new(:white, :pawn)
      move = Move.new(0, 63, piece)

      assert move.from == 0
      assert move.to == 63
      assert move.piece == piece
    end
  end
end
