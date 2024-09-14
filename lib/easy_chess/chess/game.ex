defmodule EasyChess.Chess.Game do
  @moduledoc """
  Contains a struct representing a chess game.
  """
  @derive Jason.Encoder
  defstruct board: EasyChess.Chess.Board.new(), turn: :white, moves: []

  @doc """
  Initializes a new chess game with the default starting position.
  """
  def new do
    %EasyChess.Chess.Game{board: EasyChess.Chess.Board.new()}
  end
end
