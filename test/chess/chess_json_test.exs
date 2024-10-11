defmodule ChessJsonTest do
  use ExUnit.Case

  alias EasyChess.Chess.{Piece, Move, Game}

  describe "encodes and decodes structures" do
    test "encodes and decodes the piece struct" do
      piece = %Piece{color: :white, piece: :pawn}

      assert piece == Poison.decode!(Poison.encode!(piece), as: %Piece{})
    end

    test "encodes and decodes the move struct" do
      piece = %Piece{color: :white, piece: :pawn}
      move = %EasyChess.Chess.Move{from: 0, to: 0, piece: piece}

      assert move == Poison.decode!(Poison.encode!(move), as: %Move{})
    end

    test "encodes and decodes the game struct" do
      game = Game.new()

      assert game == Poison.decode!(Poison.encode!(game), as: %Game{})
    end

    test "encodes and decodes the game struct with a previous move" do
      game = Game.new()
      move = Move.new(0, 0, %Piece{color: :white, piece: :pawn})
      game = Game.apply_move(game, move)

      assert game == Poison.decode!(Poison.encode!(game), as: %Game{})
    end

    test "encodes and decodes the game struct with a move history" do
      game = Game.new()

      repeated_move = Move.new(0, 0, %Piece{color: :white, piece: :pawn})

      game = Game.apply_move(game, repeated_move)
      game = Game.apply_move(game, repeated_move)
      game = Game.apply_move(game, repeated_move)
      game = Game.apply_move(game, repeated_move)
      game = Game.apply_move(game, repeated_move)

      decoded_game = Poison.decode!(Poison.encode!(game), as: %Game{})

      IO.inspect(decoded_game)

      assert length(decoded_game.move_history) == 5
      assert Enum.all?(decoded_game.move_history, fn move -> move == repeated_move end)
    end
  end
end
