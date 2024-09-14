defmodule EasyChess.Chess.GamesManager do
  @moduledoc """
  Manages creation, updating, and deletion of chess games.

  Uses the `:redix` store to store games.
  """

  def create_game(code) do
    game = %EasyChess.Chess.Game{board: EasyChess.Chess.Board.new()}
    save_game_state(game, code)
  end

  def save_game_state(game, code) do
    case Jason.encode(game) do
      {:ok, json} ->
        Redix.command(:redix, ["SET", "game:#{code}", json])

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_game_state(code) do
    case Redix.command(:redix, ["GET", "game:#{code}"]) do
      {:ok, game} ->
        Jason.decode(game)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
